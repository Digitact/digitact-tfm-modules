# =============================================================================
# WineHub Naming & Tagging Module - Variables
# =============================================================================
# This module will be extracted to a shared repository for use across
# all WineHub Terraform configurations.
#
# Repository: github.com/winehub/terraform-winehub-naming (future)
# =============================================================================

variable "product" {
  description = "Product prefix for resource naming"
  type        = string
  default     = "whub"
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
  description = "Application name (e.g., zoho-crm, analytics, api)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.application))
    error_message = "Application must be 3-20 lowercase alphanumeric characters with hyphens"
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
