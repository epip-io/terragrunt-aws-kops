provider "aws" {
  region  = var.aws_region
}

provider "kops" {
    state_store = var.state_store
}

locals {
    private_subnets = [
        for subnet in setproduct(var.azs, var.private_subnets, var.private_subnets_cidr_blocks, var.private_subnets_egresses) : {
            name = format("%s-private-%s", var.name, subnet[0])
            id = subnet[1]
            zone = subnet[0]
            cidr = subnet[2]
            type = "Private"
            egress = subnet[3]
            hosts = pow(2, parseint(split("/", subnet[2])[1], 10))
        }
    ]

    utility_subnets = [
        for subnet in setproduct(var.azs, var.utility_subnets, var.utility_subnets_cidr_blocks) : {
            name = format("%s-utility-%s", var.name, subnet[0])
            id   = subnet[1]
            zone = subnet[0]
            cidr = subnet[2]
            type = "Utility"
        }
    ]

    subnets = flatten([local.private_subnets, local.utility_subnets])

    etcd_clusters = [
        for name in tolist(["main", "events"]) : {
            name          = name
            enable_etcd_tls = true
            version       = var.etcd_version
            members       = [
                for zone in var.azs : {
                    instance_group = format("master-%s", zone)
                    name           = format("etcd-%s-%s", name, zone)
                }
            ]
        }
    ]
}

resource "kops_cluster" "cluster" {
    metadata {
        name = format("%s.%s", var.aws_region, var.name)
    }

    spec {
        cloud_provider     = "aws"
        kubernetes_version = var.kubernetes_version

        network_cidr        = var.network_cidr
        non_masquerade_cidr = var.non_masquerade_cidr

        kube_dns {
            provider = "CoreDNS"
        }

        kubelet {
            anonymous_auth = "false"
        }

        kube_controller_manager {
            horizontal_pod_autoscaler_use_rest_clients = "true"
        }

        topology {
            dns {
                type = "Private"
            }

            masters = "private"
            nodes   = "private"
        }

        networking {
            calico {
                cross_subnet = "true"
                major_version = "v3"
            }
        }

        dynamic "subnets" {
            for_each = local.private_subnets

            content {
                name   = subnets.value.name
                id     = subnets.value.id
                zone   = subnets.value.zone
                cidr   = subnets.value.cidr
                type   = subnets.value.type
                egress = subnets.value.egress
            }
        }

        dynamic "subnets" {
            for_each = local.utility_subnets

            content {
                name   = subnets.value.name
                id     = subnets.value.id
                zone   = subnets.value.zone
                cidr   = subnets.value.cidr
                type   = subnets.value.type
            }
        }

        dynamic "etcd_clusters" {
            for_each = [
                    for name in tolist(["main", "events"]) : {
                        name          = name
                        version       = var.etcd_version
                        members       = [
                            for zone in var.azs : {
                                instance_group = format("master-%s", zone)
                                name           = format("etcd-%s-%s", name, zone)
                            }
                        ]
                    }
                ]
            
            content {
                name            = etcd_clusters.value.name
                version         = etcd_clusters.value.version
                enable_etcd_tls = true

                dynamic "etcd_members" {
                    for_each = etcd_clusters.value.members

                    content {
                        name           = etcd_members.value.name
                        instance_group = etcd_members.value.instance_group
                    }
                }
            }
        }

        kubernetes_api_access = var.admin_cidrs
        ssh_access            = var.admin_cidrs

        master_internal_name = format("api.internal.%s", var.name)
        master_public_name   = format("api.%s", var.name)
    }
}

resource "kops_instance_group" "masters" {
    for_each = var.azs

    metadata {
        name = format("master-%s", each.value)

        labels = tomap({
            "kops.k8s.io/cluster" = var.name
        })
    }

    spec {
        machine_type = var.master_machine_type

        cloud_labels = tomap({
            format("kubernetes.io/cluster/%s", var.name) = "owned"
        })

        node_labels = tomap({
            "kops.k8s.io/instancegroup" = format("master-%s", each.value)
        })

        role = "Master"

        subnets = [
            each.value
        ]

        min_size = 1
        max_size = 1
    }
}

resource "kops_instance_group" "nodes" {
    for_each = {
        for az in setproduct(var.azs, local.private_subnets):
        az[0] => (az[1].hosts - 3)
    }

    metadata {
        name = format("nodes-%s", each)
    }

    spec {
        machine_type = var.nodes_machine_type
        max_price    = var.nodes_max_price
        mixed_instances_policy {
            instances                = var.nodes_mixed_instances
            spot_allocation_strategy = var.nodes_allocation_strategy
            spot_instance_pools      = var.nodes_instance_pools

            on_demand_base = 0
        }

        cloud_labels = tomap({
            format("kubernetes.io/cluster/%s", var.name) = "owned"
        })

        node_labels = tomap({
            "k8s.io/cluster-autoscaler/enabled" = ""
            format("k8s.io/cluster-autoscaler/%s", var.name) = ""
            "kops.k8s.io/instancegroup" = format("nodes-%s", each)
        })

        role = "Node"

        subnets = [
            each
        ]

        min_size = var.nodes_min_size
        max_size = each.value
    }
}
