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
# Test: Prefix Too Long (Exceeds 32-character safe limit)
# -----------------------------------------------------------------------------
run "fail_prefix_too_long" {
  command = plan

  variables {
    product     = "digitact"           # 8 chars
    environment = "p"                  # 1 char
    application = "customer-portal-with-analytics" # 30 chars
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }
  # Total: digitact-p-customer-portal-with-analytics = 41 characters (exceeds 32-char limit)

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
    environment = "p"
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
    environment = "s"
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
    environment = "s"
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
    environment = "s"
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
    environment = "p"
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
    environment = "p"
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
    environment = "p"
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
    environment = "p"
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
    environment = "production" # Must be one of: p, pp, np, s, u, t, d
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
    environment = "p"
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
    environment = "p"
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
    environment = "p"
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
    environment = "p"
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
    environment = "p"
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
    environment = "p"
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
    environment = "p"
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
# For whub-p-{app}: 4 + 1 + 2 hyphens = 7 chars used
# Remaining for app to stay at 32-char limit: 32 - 7 = 25 chars
run "pass_application_at_max_length" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "app-twenty-five-chars1234" # Exactly 25 characters (max for this prefix combo)
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # This should NOT fail - prefix should be exactly 32 chars (at safe limit)
  # No expect_failures means we expect success
  assert {
    condition     = length(output.prefix) == 32
    error_message = "Prefix should be exactly 32 characters (at safe limit), got ${length(output.prefix)}"
  }
}

# -----------------------------------------------------------------------------
# Test: Prefix Exactly at Safe Limit (Should Pass)
# -----------------------------------------------------------------------------
# For whub-np-{app}: 4 + 2 + 2 hyphens = 8 chars used
# Remaining for app to stay at 32-char limit: 32 - 8 = 24 chars
run "pass_prefix_at_safe_limit" {
  command = plan

  variables {
    product     = "whub"
    environment = "np"
    application = "app-twenty-four-chars123" # Exactly 24 characters
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # This should NOT fail - it's exactly at the 32-char safe boundary
  # whub-np-app-twenty-four-chars123 = 4 + 2 + 24 + 2 = 32 chars
  assert {
    condition     = length(output.prefix) == 32
    error_message = "Prefix should be exactly 32 characters (at safe limit), got ${length(output.prefix)}"
  }
}
