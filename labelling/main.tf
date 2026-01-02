# =============================================================================
# Digitact Resource Labelling Module
# =============================================================================
# Generates compliant resource names and mandatory tags per NEW_ACCOUNT_STANDARDS.md
#
# This module is part of the digitact-tfm-modules repository:
#   github.com/digitact/digitact-tfm-modules//labelling
#
# Usage:
#   module "naming" {
#     source      = "github.com/digitact/digitact-tfm-modules//labelling"  # future
#     source      = "./modules/labelling"                                   # current
#     environment = "stg"
#     application = "zoho-crm"
#   }
#
# Naming Convention: {product}-{env}-{app}-{resource}
# Example: whub-stg-zoho-crm-lambda
#
# Required Tags (6 per NEW_ACCOUNT_STANDARDS.md):
#   - Application
#   - Environment
#   - Criticality
#   - Backup
#   - ManagedBy
#   - Layer
# =============================================================================
#
# NOTE: Local values, naming constraints, and validations are defined in locals.tf
