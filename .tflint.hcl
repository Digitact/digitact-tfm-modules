# =============================================================================
# tflint Configuration for Digitact Terraform Modules
# =============================================================================
#
# This configuration enables comprehensive linting for all Terraform modules
# in the digitact-tfm-modules repository.
#
# Usage:
#   Via Makefile: make tf-lint
#   Via Docker:   docker run --rm -v $(pwd):/workspace -w /workspace \
#                 ghcr.io/terraform-linters/tflint:v0.60.0 \
#                 sh -c "tflint --init && tflint --recursive"
#
# Documentation: https://github.com/terraform-linters/tflint
# =============================================================================

# Terraform Plugin (recommended rules)
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# AWS Plugin (AWS-specific rules)
plugin "aws" {
  enabled = true
  version = "0.45.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# =============================================================================
# Global Rules
# =============================================================================

# Enforce naming conventions
rule "terraform_naming_convention" {
  enabled = true

  # Variable naming
  variable {
    format = "snake_case"
  }

  # Local value naming
  locals {
    format = "snake_case"
  }

  # Output naming
  output {
    format = "snake_case"
  }

  # Resource naming (allow mixed for AWS resources)
  resource {
    format = "snake_case"
  }

  # Module naming
  module {
    format = "snake_case"
  }
}

# Require variable descriptions
rule "terraform_documented_variables" {
  enabled = true
}

# Require output descriptions
rule "terraform_documented_outputs" {
  enabled = true
}

# Check for unused declarations
rule "terraform_unused_declarations" {
  enabled = true
}

# Require typed variables
rule "terraform_typed_variables" {
  enabled = true
}

# Check for deprecated syntax
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

# Standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Comment syntax
rule "terraform_comment_syntax" {
  enabled = true
}

# Workspace remote configuration
rule "terraform_workspace_remote" {
  enabled = true
}

# =============================================================================
# AWS-Specific Rules (examples)
# =============================================================================

# These rules are automatically loaded via the AWS plugin.
# Configure specific AWS rules here if needed.

# Example: Enforce specific instance types
# rule "aws_instance_invalid_type" {
#   enabled = true
# }
