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
  # Based on AWS documentation, these are the character limits for resource names.
  # We reserve 6 characters for developer suffixes (e.g., "-abcde")
  #
  # Reference: https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html

  naming_limits = {
    # MOST RESTRICTIVE RESOURCES (32 characters)
    alb_nlb = {
      max_total      = 32 # AWS limit for ALB/NLB names
      reserved       = 6  # Reserved for developer suffixes
      longest_suffix = 4  # "-alb" or "-nlb"
      max_prefix     = 22 # 32 - 4 - 6 = 22
    }

    target_group = {
      max_total      = 32 # AWS limit for target group names
      reserved       = 6
      longest_suffix = 8  # "-nlb-tg"
      max_prefix     = 18 # 32 - 8 - 6 = 18
    }

    # MODERATE RESTRICTIONS (63-64 characters)
    rds_instance = {
      max_total      = 63 # AWS limit: 1-63 alphanumeric or hyphens
      reserved       = 6
      longest_suffix = 13 # "-aurora-inst"
      max_prefix     = 44 # 63 - 13 - 6 = 44
    }

    s3_bucket = {
      max_total      = 63 # AWS limit: 3-63 characters
      reserved       = 6
      longest_suffix = 10                             # "-artifacts"
      max_prefix     = 47                             # 63 - 10 - 6 = 47
      pattern        = "^[a-z0-9][a-z0-9-]*[a-z0-9]$" # Lowercase, no underscores
    }

    iam_role = {
      max_total      = 64 # AWS limit for role names
      reserved       = 6
      longest_suffix = 20 # "-ecs-exec-role" or similar
      max_prefix     = 38 # 64 - 20 - 6 = 38
    }

    iam_user = {
      max_total      = 64
      reserved       = 6
      longest_suffix = 5  # "-user"
      max_prefix     = 53 # 64 - 5 - 6 = 53
    }

    lambda = {
      max_total      = 64 # AWS limit for function names
      reserved       = 6
      longest_suffix = 17 # "-lambda-permission" (longest in our set)
      max_prefix     = 41 # 64 - 17 - 6 = 41
    }

    sqs_queue = {
      max_total      = 80 # AWS limit for SQS queue names
      reserved       = 6
      longest_suffix = 24 # "-sqs_queue_high_priority" (PROBLEM!)
      max_prefix     = 50 # 80 - 24 - 6 = 50
      note           = "FIFO queues must end with .fifo"
    }

    # GENEROUS LIMITS (128+ characters)
    iam_policy = {
      max_total      = 128
      reserved       = 6
      longest_suffix = 7   # "-policy"
      max_prefix     = 115 # 128 - 7 - 6 = 115
    }

    security_group = {
      max_total      = 255
      reserved       = 6
      longest_suffix = 13  # "-bastion-sg" or similar
      max_prefix     = 236 # 255 - 13 - 6 = 236
    }

    ecs_cluster = {
      max_total      = 255
      reserved       = 6
      longest_suffix = 19  # "-capacity-provider" (within ECS family)
      max_prefix     = 230 # 255 - 19 - 6 = 230
    }

    log_group = {
      max_total      = 512
      reserved       = 6
      longest_suffix = 30  # "/aws/lambda/" prefix + name
      max_prefix     = 476 # 512 - 30 - 6 = 476
    }
  }

  # ==========================================================================
  # VALIDATION: Check prefix against most restrictive limit
  # ==========================================================================
  # The most restrictive resource is Target Group at max_prefix=18 characters
  # However, this would be too restrictive for general use.
  #
  # We'll validate against ALB/NLB limit (22 chars) as a practical maximum
  # and document resources that need shorter prefixes.

  max_safe_prefix_length = 22 # Based on ALB/NLB constraints

  prefix_validation = {
    is_valid = local.prefix_length <= local.max_safe_prefix_length
    message  = "Prefix '${local.prefix}' is ${local.prefix_length} characters. Maximum recommended is ${local.max_safe_prefix_length} to support ALB/NLB resources with 6-character developer suffix buffer."
  }

  # ==========================================================================
  # WARNING MESSAGES for resources with tight constraints
  # ==========================================================================
  # Resources that may exceed limits with the current prefix

  resource_warnings = {
    target_group = local.prefix_length > 18 ? "WARNING: Prefix length ${local.prefix_length} may exceed Target Group limit (18 chars recommended)" : ""
    alb_nlb      = local.prefix_length > 22 ? "WARNING: Prefix length ${local.prefix_length} may exceed ALB/NLB limit (22 chars recommended)" : ""
  }

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
