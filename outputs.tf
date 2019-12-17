output "cluster_name" {
    description = "Cluster name is computed using aws_region and name variables"
    value       = "${local.name}"
}

output "admin_cidrs" {
    description = "Pass-through value for dependent modules"
    value       = var.admin_cidrs
}

output "nodes_igs" {
    description = "List of Nodes Instance Group Names"
    value       = kops_instance_group.nodes
}
