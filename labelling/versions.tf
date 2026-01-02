terraform {
  required_version = ">= 1.6.0" # Required for terraform test support

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
