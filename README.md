# Digitact Terraform Modules

Shared Terraform modules for Digitact infrastructure across all products.

## Overview

This repository contains reusable Terraform modules used across Digitact's product portfolio, including Winehub, Perkrunner, and future products. These modules enforce consistent naming conventions, tagging standards, and infrastructure patterns across all AWS deployments.

## Repository Purpose

- **Centralized Module Management**: Single source of truth for shared Terraform modules
- **Consistency**: Enforce standardized naming and tagging across products
- **Reusability**: DRY principle applied to infrastructure code
- **Multi-Product Support**: Modules designed to work across Digitact's product ecosystem

## Available Modules

### Labelling Module

Path: `labelling/`

Generates compliant resource names and mandatory tags according to Digitact's infrastructure standards.

**Features:**
- Standardized resource naming: `{product}-{env}-{app}-{resource}`
- Mandatory tag generation (Application, Environment, Criticality, Backup, ManagedBy, Layer)
- Environment-specific configurations
- Consistent prefixes for resource identification

**Usage:**
```hcl
module "naming" {
  source = "github.com/digitact/digitact-tfm-modules//labelling"

  product     = "whub"        # or "prkr" for Perkrunner
  environment = "stg"
  application = "zoho-crm"
  criticality = "medium"
  backup      = "daily"
  layer       = "application"
}

# Use the outputs
resource "aws_lambda_function" "example" {
  function_name = module.naming.name.lambda
  tags          = module.naming.default_tags
}
```

## Module Development Guidelines

When adding new modules to this repository:

1. **Directory Structure**: Each module should have its own directory at the root level
2. **Standard Files**: Include `main.tf`, `variables.tf`, `outputs.tf`, and module-specific README
3. **Documentation**: Document inputs, outputs, and usage examples
4. **Product Agnostic**: Design modules to work across all Digitact products
5. **Versioning**: Use git tags for versioning (e.g., `v1.0.0`, `labelling-v1.0.0`)

## Products Using This Repository

- **Winehub** (`whub`) - Wine industry platform
- **Perkrunner** (`prkr`) - Perks and benefits platform
- Additional products as the portfolio grows

## Naming Convention

Repository: `digitact-tfm-modules`
- `digitact` - Company name
- `tfm` - Terraform modules identifier
- `modules` - Indicates this contains multiple modules

## Contributing

When contributing new modules:
1. Create module in its own directory
2. Follow existing module patterns
3. Include comprehensive documentation
4. Test across multiple products where applicable
5. Submit pull request for review

## Support

For issues or questions about these modules, please contact the Digitact infrastructure team.
