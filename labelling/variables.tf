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
  description = "Environment code (p=production, pp=preprod, np=nonprod, s=staging, u=uat, t=test, d=development)"
  type        = string

  validation {
    condition     = contains(["p", "pp", "np", "s", "u", "t", "d"], var.environment)
    error_message = "Environment must be one of: p (production), pp (preprod), np (nonprod), s (staging), u (uat), t (test), d (development)"
  }
}

variable "application" {
  description = <<-EOD
    Application name (e.g., zoho-crm, analytics, api, observability)

    Naming pattern: {product}-{env}-{app}
    Example: whub-np-observability (21 chars)

    Recommended: Keep total prefix under 32 characters for ALB/NLB compatibility.
    With short environments (p, np, d, s), you have plenty of room for descriptive names.

    Examples:
    - whub-p-api (10 chars) ✓
    - whub-p-analytics (16 chars) ✓
    - whub-np-observability (21 chars) ✓
    - whub-p-customer-portal (22 chars) ✓
  EOD
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.application))
    error_message = "Application must contain only lowercase letters, numbers, and hyphens. Must start with a letter and end with a letter or number. No consecutive hyphens, no leading/trailing hyphens."
  }

  validation {
    condition     = length(var.application) >= 3 && length(var.application) <= 50
    error_message = "Application name must be 3-50 characters long."
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

variable "repository" {
  description = "Git repository name (e.g., 'howards-folly-wine', 'agnostic-1'). Used for the Repository tag to track which codebase manages this infrastructure."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-_]*[a-z0-9]$", var.repository))
    error_message = "Repository must contain only lowercase letters, numbers, hyphens, and underscores. Must start and end with a letter or number."
  }

  validation {
    condition     = length(var.repository) >= 2 && length(var.repository) <= 100
    error_message = "Repository name must be 2-100 characters long."
  }
}

variable "additional_tags" {
  description = "Additional tags to merge with mandatory tags"
  type        = map(string)
  default     = {}
}

