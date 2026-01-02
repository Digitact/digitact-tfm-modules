# =============================================================================
# WineHub Naming & Tagging Module - Variables
# =============================================================================
# This module will be extracted to a shared repository for use across
# all WineHub Terraform configurations.
#
# Repository: github.com/winehub/terraform-winehub-naming (future)
# =============================================================================

variable "product" {
  description = "Product prefix for resource naming (e.g., 'whub' for WineHub, 'prkr' for PerkRunner)"
  type        = string
  default     = "whub"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,7}$", var.product))
    error_message = "Product must be 3-8 lowercase alphanumeric characters, starting with a letter. Examples: whub, prkr, dgtct"
  }
}

variable "environment" {
  description = "Environment code (prd, nprd, dev, stg)"
  type        = string

  validation {
    condition     = contains(["prd", "nprd", "dev", "stg"], var.environment)
    error_message = "Environment must be one of: prd, nprd, dev, stg"
  }
}

variable "application" {
  description = <<-EOD
    Application name (e.g., zoho-crm, analytics, api)

    IMPORTANT: Total prefix length (product-env-app) should not exceed 22 characters
    to ensure compatibility with ALB/NLB resources and allow 6-character developer suffixes.

    Examples:
    - whub-prd-api (11 chars) ✓
    - whub-prd-analytics (17 chars) ✓
    - whub-nprd-zoho-crm (16 chars) ✓
    - whub-prd-customer-portal (23 chars) ✗ TOO LONG for ALB/NLB
  EOD
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.application))
    error_message = "Application must contain only lowercase letters, numbers, and hyphens. Must start with a letter and end with a letter or number. No consecutive hyphens, no leading/trailing hyphens."
  }

  validation {
    condition     = length(var.application) >= 3 && length(var.application) <= 20
    error_message = "Application name must be 3-20 characters long to ensure total prefix stays within AWS resource naming limits."
  }

  validation {
    condition     = !can(regex("--", var.application))
    error_message = "Application name cannot contain consecutive hyphens (--). This violates AWS naming rules for RDS, S3, and other resources."
  }
}

# =============================================================================
# Mandatory Tag Variables (per NEW_ACCOUNT_STANDARDS.md)
# =============================================================================

variable "criticality" {
  description = "Business criticality level for support prioritization"
  type        = string
  default     = "medium"

  validation {
    condition     = contains(["critical", "high", "medium", "low"], var.criticality)
    error_message = "Criticality must be one of: critical, high, medium, low"
  }
}

variable "backup" {
  description = "Backup tier for retention policy"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "tier-1", "tier-2", "tier-3"], var.backup)
    error_message = "Backup must be one of: none, tier-1, tier-2, tier-3"
  }
}

variable "layer" {
  description = "Architecture layer designation"
  type        = string
  default     = "application"

  validation {
    condition     = contains(["governance", "shared-infrastructure", "application"], var.layer)
    error_message = "Layer must be one of: governance, shared-infrastructure, application"
  }
}

variable "additional_tags" {
  description = "Additional tags to merge with mandatory tags"
  type        = map(string)
  default     = {}
}
