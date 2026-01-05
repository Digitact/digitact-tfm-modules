terraform {
  required_version = ">= 1.14.0" # Requires Terraform 1.14.x for latest features and fixes

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0" # AWS provider 6.x with multi-region support
    }
  }
}
