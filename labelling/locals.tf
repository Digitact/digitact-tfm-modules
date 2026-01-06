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
  # Example: "whub-np-observability"
  # No resource-type suffixes - keeps names simple and consistent
  prefix = "${var.product}-${var.environment}-${var.application}"

  # Calculate prefix length for validation
  prefix_length = length(local.prefix)

  # ==========================================================================
  # Naming Validation
  # ==========================================================================
  # Set to 32 chars (ALB/NLB AWS limit) - fits most use cases
  # With short environments (p, np, etc), names like "whub-np-observability"
  # easily fit within this limit
  max_prefix_length = 32

  # ==========================================================================
  # Environment Display Mapping
  # ==========================================================================
  environment_display = {
    p  = "production"
    pp = "preprod"
    np = "nonprod"
    s  = "staging"
    u  = "uat"
    t  = "test"
    d  = "development"
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

# Check 1: Prefix length validation
check "prefix_length_validation" {
  assert {
    condition     = local.prefix_length <= local.max_prefix_length
    error_message = <<-EOT
      Naming prefix '${local.prefix}' is ${local.prefix_length} characters long.
      Maximum allowed: ${local.max_prefix_length} characters (ALB/NLB compatibility)

      Current breakdown:
      - Product: '${var.product}' (${length(var.product)} chars)
      - Environment: '${var.environment}' (${length(var.environment)} chars)
      - Application: '${var.application}' (${length(var.application)} chars)
      - Hyphens: 2
      - Total: ${local.prefix_length} chars
      - Over limit by: ${local.prefix_length - local.max_prefix_length} chars

      TO FIX (choose one):

      Option 1: Shorten application name (recommended)
        Reduce to ${local.max_prefix_length - length(var.product) - length(var.environment) - 2} characters or less
        Example: "customer-portal" → "custport" (saves 8 chars)

      Option 2: Use shorter product code
        Current: product = "${var.product}" (${length(var.product)} chars)
        Example: "whub" → "wh" (saves 2 chars)

      Option 3: Use abbreviated environment (if not already)
        Current options: p, pp, np, s, u, t, d (1-2 chars each)

      VALID EXAMPLES:
      - whub-p-api (10 chars) ✓
      - whub-p-analytics (16 chars) ✓
      - whub-np-observability (21 chars) ✓
      - whub-p-customer-portal (22 chars) ✓

      Note: Resource type is identified by AWS resource tags, not the name suffix.
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
