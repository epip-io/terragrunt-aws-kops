variable "aws_region" {
    type    = string
    default = "us-east-1"
}

variable "name" {
    type = string
}

variable "state_store" {
    description = "S3 bucket to use for Kops state"
    type        = string
}
variable "dns_zone" {
    description = "AWS Route53 Zone ID to use"
    type        = string
}

variable "oidc_issuer_url" {
    type = string
}

variable "oidc_client_id" {
    type = string
}

variable "oidc_username_claim" {
    type    = string
    default = "email"
}

variable "oidc_group_claim" {
    type    = string
    default = "group"
}

variable "network_cidr" {
    description = "Usually mapped to `aws_vpc.output.vpc_cidr_block`"
    type = string
}

variable "network_id" {
    description = "Usually mapped to `aws_vpc.output.vpc_id`"
    type = string
}

variable "admin_cidrs" {
    description = "List of CIDRs to allow API and SSH access"
    type        = list(string)
}

variable "azs" {
    description = "Usually maps to the same variable in `aws_vpc.output.azs`"
    type        = list(string)
    default     = [
        "us-east-1a",
        "us-east-1b",
        "us-east-1c",
    ]
}

variable "utility_subnets" {
    description = "Usually maps to `aws_vpc.output.public_subnets`"
    type        = list(string)
}

variable "utility_subnets_cidr_blocks" {
    description = "Usually maps to `aws_vpc.output.public_subnets_cidr_blocks`"
    type        = list(string)
}

variable "private_subnets" {
    description = "Usually maps to the same variable in `aws_vpc.output.private_subnets`"
    type        = list(string)
}

variable "private_subnets_cidr_blocks" {
    description = "Usually maps to the same variable in `aws_vpc.output.private_subnets_cidr_blocks`"
    type = list(string)
}

variable "private_subnets_egresses" {
    description = "Usually maps to `aws_vpc.output.natgw_ids`"
    type = list(string)
}

variable "etcd_version" {
    description = "etcd Docker image tag"
    type        = string
    default     = "3.4.3"
}

variable "kubernetes_version" {
    description = "Kubernetes version to use"
    type        = string
    default     = "1.15.6"
}

variable "non_masquerade_cidr" {
    description = "Non-masquerade CIDR for Pods"
    type        = string
    default     = "10.0.0.0/16"
}

variable "master_machine_type" {
    description = "EC2 instance type to use for Masters"
    type        = string
    default     = "t3.medium"
}

variable "nodes_allocation_strategy" {
    description = "Spot instance alloction strategy to use for Nodes (lowest-price or capacity-optimized)"
    type        = string
    default     = "lowest-price"
}

variable "nodes_machine_type" {
    description = "Primary EC2 instancetype to use for Nodes"
    type        = string
    default     = "m5.xlarge"
}

# https://www.ec2instances.info/
variable "nodes_mixed_instances" {
    description = "List of EC2 instance types to use for Nodes"
    type        = list(string)
    default     = [
        "m5.xlarge",
        "m5a.xlarge",
        "m5ad.xargle",
        "m5dn.xlarge",
        "m5d.xlarge",
        "m5n.xlarge",
        "m4.xlarge",
    ]
}

variable "nodes_max_price" {
    description = "Max price for instances used for Nodes"
    type        = number
    default     = 0.10
}

variable "nodes_instance_pools" {
    description = "Spot instance pools to use for Nodes (usually number of mixed instance types minux 1)"
    type        = number
    default     = 6
}

variable "nodes_min_size" {
    description = "Min number of instances in each AZ for Nodes"
    type        = number
    default     = 1
}
