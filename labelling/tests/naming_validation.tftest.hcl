# =============================================================================
# Naming Validation Tests
# =============================================================================
# Tests core naming constraint validations without creating real AWS resources
# Uses command = plan to validate logic without infrastructure deployment
# =============================================================================

# Mock AWS provider - no real AWS resources will be created
mock_provider "aws" {}

# =============================================================================
# Test 1: Valid Short Prefix
# =============================================================================
run "valid_short_prefix" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "api"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
  }

  # Verify prefix is correct
  assert {
    condition     = output.prefix == "whub-stg-api"
    error_message = "Prefix should be 'whub-stg-api' but got '${output.prefix}'"
  }

  # Verify prefix length is acceptable
  assert {
    condition     = length(output.prefix) == 12
    error_message = "Prefix length should be 12 characters but got ${length(output.prefix)}"
  }

  # Verify ALB name is within limits (should be 15 chars: whub-stg-api-alb)
  assert {
    condition     = length(output.name.alb) <= 26
    error_message = "ALB name '${output.name.alb}' is ${length(output.name.alb)} chars, should be ≤26 to allow 6-char suffix"
  }

  # Verify mandatory tags are present
  assert {
    condition     = output.mandatory_tags.Application == "api"
    error_message = "Application tag should be 'api'"
  }

  assert {
    condition     = output.mandatory_tags.Environment == "staging"
    error_message = "Environment tag should be 'staging'"
  }

  assert {
    condition     = output.mandatory_tags.ManagedBy == "Terraform"
    error_message = "ManagedBy tag should be 'Terraform'"
  }
}

# =============================================================================
# Test 2: Valid Longer Prefix (Near Limit)
# =============================================================================
run "valid_longer_prefix" {
  command = plan

  variables {
    product     = "whub"
    environment = "nprd"
    application = "analytics"
    criticality = "medium"
    backup      = "tier-2"
    layer       = "application"
  }

  # Verify prefix is constructed correctly
  assert {
    condition     = output.prefix == "whub-nprd-analytics"
    error_message = "Expected 'whub-nprd-analytics' but got '${output.prefix}'"
  }

  # This is intentionally near the limit - 19 chars, well within the 22-char safe limit
  assert {
    condition     = length(output.prefix) <= 22
    error_message = "Prefix length ${length(output.prefix)} exceeds safe limit of 22 characters"
  }
}

# =============================================================================
# Test 3: S3 Bucket Lowercase Validation
# =============================================================================
run "s3_lowercase_check" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "data-lake"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
  }

  # Verify S3 bucket name contains only lowercase
  assert {
    condition     = can(regex("^[a-z0-9-]+$", output.name.s3_bucket))
    error_message = "S3 bucket name must contain only lowercase letters, numbers, and hyphens"
  }

  # Verify no uppercase in prefix
  assert {
    condition     = output.prefix == lower(output.prefix)
    error_message = "Prefix must be lowercase for S3 compatibility"
  }
}

# =============================================================================
# Test 4: No Consecutive Hyphens
# =============================================================================
run "no_consecutive_hyphens" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "web-api"
    criticality = "high"
    backup      = "none"
    layer       = "application"
  }

  # Verify no consecutive hyphens in prefix
  assert {
    condition     = !can(regex("--", output.prefix))
    error_message = "Prefix contains consecutive hyphens which violates AWS naming rules"
  }

  # Verify RDS instance name compliance
  assert {
    condition     = !can(regex("--", output.name.rds_instance))
    error_message = "RDS instance name contains consecutive hyphens"
  }
}

# =============================================================================
# Test 5: No Leading/Trailing Hyphens
# =============================================================================
run "no_leading_trailing_hyphens" {
  command = plan

  variables {
    product     = "prkr"
    environment = "prd"
    application = "benefits"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
  }

  # Verify no leading hyphen
  assert {
    condition     = !can(regex("^-", output.prefix))
    error_message = "Prefix starts with hyphen which violates AWS naming rules"
  }

  # Verify no trailing hyphen
  assert {
    condition     = !can(regex("-$", output.prefix))
    error_message = "Prefix ends with hyphen which violates AWS naming rules"
  }
}

# =============================================================================
# Test 6: SQS FIFO Queue Naming
# =============================================================================
run "sqs_fifo_naming" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "orders"
    criticality = "critical"
    backup      = "none"
    layer       = "application"
  }

  # Verify FIFO queue has .fifo suffix
  assert {
    condition     = can(regex("\\.fifo$", output.name.sqs_queue_fifo))
    error_message = "FIFO queue name must end with .fifo"
  }

  # Verify standard queue doesn't have .fifo
  assert {
    condition     = !can(regex("\\.fifo", output.name.sqs_queue))
    error_message = "Standard queue should not have .fifo suffix"
  }
}

# =============================================================================
# Test 7: All Output Keys Exist
# =============================================================================
run "output_keys_exist" {
  command = plan

  variables {
    product     = "whub"
    environment = "dev"
    application = "test"
    criticality = "low"
    backup      = "none"
    layer       = "application"
  }

  # Verify critical output keys exist
  assert {
    condition     = output.name.lambda != null && output.name.lambda != ""
    error_message = "Lambda name output is missing or empty"
  }

  assert {
    condition     = output.name.alb != null && output.name.alb != ""
    error_message = "ALB name output is missing or empty"
  }

  assert {
    condition     = output.name.rds_instance != null && output.name.rds_instance != ""
    error_message = "RDS instance name output is missing or empty"
  }

  assert {
    condition     = output.name.s3_bucket != null && output.name.s3_bucket != ""
    error_message = "S3 bucket name output is missing or empty"
  }

  assert {
    condition     = output.name.sqs_queue != null && output.name.sqs_queue != ""
    error_message = "SQS queue name output is missing or empty"
  }

  assert {
    condition     = output.mandatory_tags != null
    error_message = "Mandatory tags output is missing"
  }
}

# =============================================================================
# Test 8: Environment Display Names
# =============================================================================
run "environment_display_names" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
  }

  assert {
    condition     = output.environment_display == "production"
    error_message = "Production environment display should be 'production' but got '${output.environment_display}'"
  }
}

# =============================================================================
# Test 9: Tags with Name Helper
# =============================================================================
run "tags_with_name_helper" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "web"
    criticality = "medium"
    backup      = "tier-2"
    layer       = "application"
  }

  # Verify tags_with_name includes Name tag
  assert {
    condition     = output.tags_with_name.vpc.Name == "whub-stg-web-vpc"
    error_message = "VPC Name tag incorrect"
  }

  # Verify tags_with_name includes mandatory tags
  assert {
    condition     = output.tags_with_name.vpc.Application == "web"
    error_message = "VPC Application tag missing or incorrect"
  }

  assert {
    condition     = output.tags_with_name.vpc.ManagedBy == "Terraform"
    error_message = "VPC ManagedBy tag missing or incorrect"
  }
}

# =============================================================================
# Test 10: Additional Tags Merge
# =============================================================================
run "additional_tags_merge" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "crm"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    additional_tags = {
      CostCenter = "Engineering"
      Owner      = "Platform Team"
    }
  }

  # Verify additional tags are included
  assert {
    condition     = output.mandatory_tags.CostCenter == "Engineering"
    error_message = "Additional tag 'CostCenter' not merged correctly"
  }

  assert {
    condition     = output.mandatory_tags.Owner == "Platform Team"
    error_message = "Additional tag 'Owner' not merged correctly"
  }

  # Verify mandatory tags still exist
  assert {
    condition     = output.mandatory_tags.Application == "crm"
    error_message = "Application tag missing after additional tags merge"
  }
}
