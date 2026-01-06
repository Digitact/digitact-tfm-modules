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
    environment = "s"
    application = "api"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify prefix is correct
  assert {
    condition     = output.prefix == "whub-s-api"
    error_message = "Prefix should be 'whub-s-api' but got '${output.prefix}'"
  }

  # Verify prefix length is acceptable
  assert {
    condition     = length(output.prefix) == 10
    error_message = "Prefix length should be 10 characters but got ${length(output.prefix)}"
  }

  # Verify clean name matches prefix (simplified naming)
  assert {
    condition     = output.name == "whub-s-api"
    error_message = "Clean name should be 'whub-s-api' but got '${output.name}'"
  }

  # Verify ALB name with suffix is within limits
  assert {
    condition     = length(output.name_with_suffix.alb) <= 32
    error_message = "ALB name '${output.name_with_suffix.alb}' is ${length(output.name_with_suffix.alb)} chars, should be ≤32"
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
    environment = "np"
    application = "analytics"
    criticality = "medium"
    backup      = "tier-2"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify prefix is constructed correctly
  assert {
    condition     = output.prefix == "whub-np-analytics"
    error_message = "Expected 'whub-np-analytics' but got '${output.prefix}'"
  }

  # This is within the 32-char limit
  assert {
    condition     = length(output.prefix) <= 32
    error_message = "Prefix length ${length(output.prefix)} exceeds limit of 32 characters"
  }
}

# =============================================================================
# Test 3: S3 Bucket Lowercase Validation
# =============================================================================
run "s3_lowercase_check" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "data-lake"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify S3 bucket name contains only lowercase (using clean name)
  assert {
    condition     = can(regex("^[a-z0-9-]+$", output.name))
    error_message = "S3 bucket name must contain only lowercase letters, numbers, and hyphens"
  }

  # Verify S3 bucket suffix output also lowercase
  assert {
    condition     = can(regex("^[a-z0-9-]+$", output.name_with_suffix.s3_bucket))
    error_message = "S3 bucket suffix name must contain only lowercase letters, numbers, and hyphens"
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
    environment = "s"
    application = "web-api"
    criticality = "high"
    backup      = "none"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify no consecutive hyphens in prefix
  assert {
    condition     = !can(regex("--", output.prefix))
    error_message = "Prefix contains consecutive hyphens which violates AWS naming rules"
  }

  # Verify clean name has no consecutive hyphens
  assert {
    condition     = !can(regex("--", output.name))
    error_message = "Name contains consecutive hyphens"
  }

  # Verify RDS instance name compliance (using suffix output)
  assert {
    condition     = !can(regex("--", output.name_with_suffix.rds_instance))
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
    environment = "p"
    application = "benefits"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
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
    environment = "p"
    application = "orders"
    criticality = "critical"
    backup      = "none"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify FIFO queue has .fifo suffix
  assert {
    condition     = can(regex("\\.fifo$", output.name_with_suffix.sqs_queue_fifo))
    error_message = "FIFO queue name must end with .fifo"
  }

  # Verify standard queue doesn't have .fifo
  assert {
    condition     = !can(regex("\\.fifo", output.name_with_suffix.sqs_queue))
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
    environment = "d"
    application = "test"
    criticality = "low"
    backup      = "none"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify critical output keys exist
  assert {
    condition     = output.name_with_suffix.lambda != null && output.name_with_suffix.lambda != ""
    error_message = "Lambda name output is missing or empty"
  }

  assert {
    condition     = output.name_with_suffix.alb != null && output.name_with_suffix.alb != ""
    error_message = "ALB name output is missing or empty"
  }

  assert {
    condition     = output.name_with_suffix.rds_instance != null && output.name_with_suffix.rds_instance != ""
    error_message = "RDS instance name output is missing or empty"
  }

  assert {
    condition     = output.name_with_suffix.s3_bucket != null && output.name_with_suffix.s3_bucket != ""
    error_message = "S3 bucket name output is missing or empty"
  }

  assert {
    condition     = output.name_with_suffix.sqs_queue != null && output.name_with_suffix.sqs_queue != ""
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
    environment = "p"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
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
    environment = "s"
    application = "web"
    criticality = "medium"
    backup      = "tier-2"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify tags_with_name includes Name tag
  assert {
    condition     = output.tags_with_name.vpc.Name == "whub-s-web-vpc"
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
    environment = "p"
    application = "crm"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
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
