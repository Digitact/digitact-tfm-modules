# =============================================================================
# Failure Scenarios Tests (Negative Testing)
# =============================================================================
# Tests that our validations correctly REJECT invalid configurations
# Uses expect_failures to verify that validations trigger as expected
#
# Note: For these tests, a PASS means the validation correctly FAILED
# =============================================================================

# Mock AWS provider - no real AWS resources will be created
mock_provider "aws" {}

# =============================================================================
# Check Block Failure Tests
# =============================================================================

# -----------------------------------------------------------------------------
# Test: Prefix Too Long (Exceeds 22-character safe limit)
# -----------------------------------------------------------------------------
run "fail_prefix_too_long" {
  command = plan

  variables {
    product     = "digitact"           # 8 chars
    environment = "prd"                # 3 chars
    application = "customer-portal-v2" # 18 chars
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }
  # Total: digitact-prd-customer-portal-v2 = 31 characters (exceeds 22-char limit)

  expect_failures = [
    check.prefix_length_validation,
  ]
}

# -----------------------------------------------------------------------------
# Test: Uppercase in S3 Bucket Names (Not Allowed)
# -----------------------------------------------------------------------------
# Note: Product variable validation catches uppercase before check block runs
run "fail_s3_uppercase" {
  command = plan

  variables {
    product     = "WHub" # Uppercase not allowed
    environment = "prd"
    application = "data-lake"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.product, # Variable validation requires lowercase
  ]
}

# -----------------------------------------------------------------------------
# Test: Leading Hyphen in Application Name
# -----------------------------------------------------------------------------
run "fail_leading_hyphen" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "-api" # Leading hyphen not allowed
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.application, # Variable validation should catch this
  ]
}

# -----------------------------------------------------------------------------
# Test: Trailing Hyphen in Application Name
# -----------------------------------------------------------------------------
run "fail_trailing_hyphen" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "api-" # Trailing hyphen not allowed
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.application, # Variable validation should catch this
  ]
}

# -----------------------------------------------------------------------------
# Test: Consecutive Hyphens in Application Name
# -----------------------------------------------------------------------------
run "fail_consecutive_hyphens" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "web--api" # Consecutive hyphens not allowed
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.application, # Variable validation should catch this
  ]
}

# =============================================================================
# Variable Validation Failure Tests
# =============================================================================

# -----------------------------------------------------------------------------
# Test: Invalid Product Code (Too Short)
# -----------------------------------------------------------------------------
run "fail_product_too_short" {
  command = plan

  variables {
    product     = "ab" # Must be 3-8 characters
    environment = "prd"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.product,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Product Code (Too Long)
# -----------------------------------------------------------------------------
run "fail_product_too_long" {
  command = plan

  variables {
    product     = "verylongproductcode" # Must be 3-8 characters
    environment = "prd"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.product,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Product Code (Uppercase Not Allowed)
# -----------------------------------------------------------------------------
run "fail_product_uppercase" {
  command = plan

  variables {
    product     = "WHub" # Must be lowercase
    environment = "prd"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.product,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Product Code (Special Characters)
# -----------------------------------------------------------------------------
run "fail_product_special_chars" {
  command = plan

  variables {
    product     = "whub!" # Only alphanumeric allowed
    environment = "prd"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.product,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Environment Code
# -----------------------------------------------------------------------------
run "fail_invalid_environment" {
  command = plan

  variables {
    product     = "whub"
    environment = "production" # Must be one of: prd, nprd, dev, stg
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.environment,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Application Name (Too Short)
# -----------------------------------------------------------------------------
run "fail_application_too_short" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "ab" # Must be 3-20 characters
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.application,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Application Name (Too Long)
# -----------------------------------------------------------------------------
run "fail_application_too_long" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "this-is-a-very-long-application-name-exceeding-limit" # Must be 3-20 characters
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.application,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Application Name (Starts with Number)
# -----------------------------------------------------------------------------
run "fail_application_starts_with_number" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "1api" # Must start with letter
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.application,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Application Name (Ends with Hyphen)
# -----------------------------------------------------------------------------
run "fail_application_ends_with_hyphen" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "api-" # Cannot end with hyphen
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.application,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Criticality Value
# -----------------------------------------------------------------------------
run "fail_invalid_criticality" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "api"
    criticality = "super-critical" # Must be: critical, high, medium, low
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.criticality,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Backup Tier
# -----------------------------------------------------------------------------
run "fail_invalid_backup" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "api"
    criticality = "critical"
    backup      = "tier-4" # Must be: none, tier-1, tier-2, tier-3
    layer       = "application"
    repository  = "test-repo"
  }

  expect_failures = [
    var.backup,
  ]
}

# -----------------------------------------------------------------------------
# Test: Invalid Layer Value
# -----------------------------------------------------------------------------
run "fail_invalid_layer" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "presentation" # Must be: governance, shared-infrastructure, application
    repository  = "test-repo"
  }

  expect_failures = [
    var.layer,
  ]
}

# =============================================================================
# Edge Cases and Boundary Testing
# =============================================================================

# -----------------------------------------------------------------------------
# Test: Application Name at Maximum Length for Prefix Limit (Should Pass)
# -----------------------------------------------------------------------------
# For whub-prd-{app}: 4 + 3 + 2 hyphens = 9 chars used
# Remaining for app to stay at 22-char limit: 22 - 9 = 13 chars
run "pass_application_at_max_length" {
  command = plan

  variables {
    product     = "whub"
    environment = "prd"
    application = "app-thirteen1" # Exactly 13 characters (max for this prefix combo)
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # This should NOT fail - prefix should be exactly 22 chars (at safe limit)
  # No expect_failures means we expect success
  assert {
    condition     = length(output.prefix) == 22
    error_message = "Prefix should be exactly 22 characters (at safe limit), got ${length(output.prefix)}"
  }
}

# -----------------------------------------------------------------------------
# Test: Prefix Exactly at Safe Limit (Should Pass)
# -----------------------------------------------------------------------------
# For whub-nprd-{app}: 4 + 4 + 2 hyphens = 10 chars used
# Remaining for app to stay at 22-char limit: 22 - 10 = 12 chars
run "pass_prefix_at_safe_limit" {
  command = plan

  variables {
    product     = "whub"
    environment = "nprd"
    application = "app-twelve12" # Exactly 12 characters
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # This should NOT fail - it's exactly at the 22-char safe boundary
  # whub-nprd-app-twelve12 = 4 + 4 + 12 + 2 = 22 chars
  assert {
    condition     = length(output.prefix) == 22
    error_message = "Prefix should be exactly 22 characters (at safe limit), got ${length(output.prefix)}"
  }
}
