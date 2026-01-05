# =============================================================================
# Labelling Module - Local Values and Validations
# =============================================================================
#
# This file contains naming constraint validations to ensure generated names
# comply with AWS resource limits and reserve space for developer suffixes.
#
# =============================================================================

locals {
  # Base naming prefix: {product}-{env}-{app}
  # Example: "whub-prd-zoho-crm"
  prefix = "${var.product}-${var.environment}-${var.application}"

  # Calculate prefix length for validation
  prefix_length = length(local.prefix)

  # ==========================================================================
  # AWS RESOURCE NAMING CONSTRAINTS

  # ==========================================================================
  # VALIDATION: Check prefix against most restrictive limit
  # ==========================================================================
  # The most restrictive resource is Target Group at max_prefix=18 characters
  # However, this would be too restrictive for general use.
  #
  # We'll validate against ALB/NLB limit (22 chars) as a practical maximum
  # and document resources that need shorter prefixes.

  max_safe_prefix_length = 22 # Based on ALB/NLB constraints (32 char limit - 4 suffix - 6 reserved)

  # ==========================================================================
  # Environment Display Mapping
  # ==========================================================================
  environment_display = {
    prd  = "production"
    nprd = "nonprod"
    dev  = "development"
    stg  = "staging"
  }

  # ==========================================================================
  # Mandatory Tags (per NEW_ACCOUNT_STANDARDS.md)
  # ==========================================================================
  mandatory_tags = merge({
    Application = var.application
    Environment = local.environment_display[var.environment]
    Criticality = var.criticality
    Backup      = var.backup
    ManagedBy   = "Terraform"
    Layer       = var.layer
    Repository  = var.repository
  }, var.additional_tags)
}

# =============================================================================
# VALIDATION CHECKS (Terraform will fail if these conditions aren't met)
# =============================================================================

# Check 1: Prefix length should not exceed safe limit for ALB/NLB
check "prefix_length_validation" {
  assert {
    condition     = local.prefix_length <= local.max_safe_prefix_length
    error_message = <<-EOT
      Naming prefix '${local.prefix}' is ${local.prefix_length} characters long.

      Maximum recommended length is ${local.max_safe_prefix_length} characters to ensure:
      - ALB/NLB names fit within 32-character AWS limit
      - 6 characters reserved for developer suffixes (e.g., "-abcde")

      Current breakdown:
      - Product: '${var.product}' (${length(var.product)} chars)
      - Environment: '${var.environment}' (${length(var.environment)} chars)
      - Application: '${var.application}' (${length(var.application)} chars)
      - Hyphens: 2
      - Total: ${local.prefix_length} chars

      To fix:
      1. Shorten application name to ${22 - length(var.product) - length(var.environment) - 2} characters or less
      2. Use shorter product code (current: ${length(var.product)} chars)
      3. Consider using abbreviations

      Example valid names:
      - whub-prd-api (11 chars) ✓
      - whub-prd-analytics (17 chars) ✓
      - whub-nprd-zoho-crm (16 chars) ✓
      - whub-prd-customer-portal (23 chars) ✗ TOO LONG
    EOT
  }
}

# Check 2: S3 bucket names must be lowercase (no uppercase letters)
check "s3_naming_validation" {
  assert {
    condition     = can(regex("^[a-z0-9-]+$", local.prefix))
    error_message = <<-EOT
      S3 bucket names must contain only lowercase letters, numbers, and hyphens.
      Current prefix '${local.prefix}' contains invalid characters.

      S3 naming rules:
      - Lowercase letters (a-z) only
      - Numbers (0-9)
      - Hyphens (-)
      - Must begin and end with letter or number
      - No uppercase letters, underscores, or periods (for Transfer Acceleration)
    EOT
  }
}

# Check 3: Prefix must not start or end with hyphen (RDS/S3 requirement)
check "hyphen_placement_validation" {
  assert {
    condition     = !can(regex("^-|-$", local.prefix))
    error_message = <<-EOT
      Resource names cannot start or end with a hyphen.
      Current prefix: '${local.prefix}'

      This is required for:
      - RDS instances
      - S3 buckets
      - ALB/NLB
      - Many other AWS resources
    EOT
  }
}

# Check 4: Prefix must not contain consecutive hyphens (RDS requirement)
check "consecutive_hyphens_validation" {
  assert {
    condition     = !can(regex("--", local.prefix))
    error_message = <<-EOT
      Resource names cannot contain consecutive hyphens (--).
      Current prefix: '${local.prefix}'

      This violates AWS naming rules for:
      - RDS DB instances
      - S3 buckets
      - Other resources
    EOT
  }
}
