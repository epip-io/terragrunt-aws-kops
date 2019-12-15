terraform {
    required_version = "~> 0.12.9"

    required_providers {
        aws  = "~> 2.40"
    }

    # This gets filled in by Terragrunt
    # backend "s3" {}
}