# WineHub Naming & Tagging Module

Terraform module for standardized AWS resource naming and mandatory tagging.

## Overview

This module provides **simplified, tag-based resource naming** aligned with AWS best practices:

- **Clean names**: `{product}-{env}-{app}` pattern (e.g., `whub-np-observability`)
- **Short environment codes**: `p`, `pp`, `np`, `s`, `u`, `t`, `d` (1-2 chars)
- **Tag-based identification**: Resource type identified by Terraform resource type and AWS tags, not name suffixes
- **32-char validation**: Ensures ALB/NLB compatibility
- **Mandatory tagging**: Automatic Application, Environment, Criticality, Backup, ManagedBy, Layer, Repository tags

## Quick Start

```hcl
module "naming" {
  source = "github.com/Digitact/digitact-tfm-modules//labelling?ref=v1.1.0"

  product     = "whub"
  environment = "np"
  application = "observability"
  repository  = "winehub-infrastructure"
}

# Use the clean name (recommended)
resource "aws_lb" "main" {
  name = module.naming.name  # whub-np-observability
  tags = module.naming.mandatory_tags
}

# Or use optional suffix for backwards compatibility
resource "aws_lb" "main" {
  name = module.naming.name_with_suffix.alb  # whub-np-observability-alb
  tags = module.naming.mandatory_tags
}
```

## Key Features

### 1. Simplified Naming

**Pattern**: `{product}-{environment}-{application}`

**Examples**:
- `whub-p-api` (10 chars) ✅
- `whub-p-analytics` (16 chars) ✅
- `whub-np-observability` (21 chars) ✅
- `whub-p-customer-portal` (22 chars) ✅

### 2. Short Environment Codes

| Code | Environment | Example |
|------|-------------|---------|
| `p` | production | `whub-p-api` |
| `pp` | preprod | `whub-pp-api` |
| `np` | nonprod | `whub-np-observability` |
| `s` | staging | `whub-s-analytics` |
| `u` | uat | `whub-u-testing` |
| `t` | test | `whub-t-experiment` |
| `d` | development | `whub-d-prototype` |

### 3. Tag-Based Resource Identification

Instead of `whub-nprd-observability-alb` (27 chars), use:
- **Name**: `whub-np-observability` (21 chars)
- **Terraform resource**: `resource "aws_lb"` (clear type)
- **Tags**: Application, Environment, etc.
- **ARN**: Contains resource type information

**AWS Recommendation**: Simplify names, use tags for metadata.

### 4. Automatic Tagging

All resources get 7 mandatory tags:
- `Application`: Application name
- `Environment`: Human-readable (production, nonprod, etc.)
- `Criticality`: critical | high | medium | low
- `Backup`: none | tier-1 | tier-2 | tier-3
- `ManagedBy`: Terraform
- `Layer`: governance | shared-infrastructure | application
- `Repository`: Git repository name

## Usage Patterns

### Single Resource (Recommended)

```hcl
resource "aws_lb" "main" {
  name = module.naming.name  # Clean: whub-np-observability
  tags = module.naming.mandatory_tags
}

resource "aws_lambda_function" "api" {
  function_name = module.naming.name  # whub-np-api
  tags          = module.naming.mandatory_tags
}
```

### Multiple Resources (Same Type)

```hcl
# Add descriptive suffix for disambiguation
resource "aws_lambda_function" "webhook" {
  function_name = "${module.naming.name}-webhook"  # whub-p-api-webhook
  tags          = module.naming.mandatory_tags
}

resource "aws_lambda_function" "processor" {
  function_name = "${module.naming.name}-processor"  # whub-p-api-processor
  tags          = module.naming.mandatory_tags
}
```

### Global Uniqueness (S3, ECR)

```hcl
# S3 buckets require global uniqueness
resource "aws_s3_bucket" "artifacts" {
  bucket = "${module.naming.name}-${data.aws_caller_identity.current.account_id}"
  # whub-p-api-123456789012
  tags   = module.naming.mandatory_tags
}
```

### Backwards Compatibility

```hcl
# Optional: Use suffix outputs during migration
resource "aws_lb" "main" {
  name = module.naming.name_with_suffix.alb  # whub-p-api-alb
  tags = module.naming.mandatory_tags
}

resource "aws_iam_role" "lambda" {
  name = module.naming.name_with_suffix.lambda_role  # whub-p-api-lambda-role
  tags = module.naming.mandatory_tags
}
```

## Validation

The module validates at `terraform plan` time:

1. **Prefix length** ≤ 32 characters (ALB/NLB limit)
2. **Lowercase only** (S3 compatibility)
3. **No leading/trailing hyphens** (RDS/S3/ALB requirement)
4. **No consecutive hyphens** (RDS requirement)

**Example error**:
```
Error: Naming prefix 'whub-np-very-long-application-name' exceeds 32-character limit.

Solutions:
1. Shorten application name to ≤24 characters
2. Use shorter product code
3. Verify short environment codes (p, pp, np, s, u, t, d)
```

## Outputs

### Primary Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `name` | Clean resource name (recommended) | `whub-np-observability` |
| `prefix` | Base naming prefix | `whub-np-observability` |
| `mandatory_tags` | All 7 mandatory tags | `{Application, Environment, ...}` |

### Helper Outputs

| Output | Description |
|--------|-------------|
| `name_with_suffix` | Optional suffixed names for backwards compatibility |
| `name_tag` | Name tags for resources that require them (subnets, security groups) |
| `tags_with_name` | Mandatory tags merged with Name tag |
| `default_tags` | Tags for AWS provider default_tags block |
| `environment_display` | Human-readable environment name |

## Documentation

- **[NAMING_CONSTRAINTS.md](./NAMING_CONSTRAINTS.md)**: AWS resource limits, validation details, best practices
- **[outputs.tf](./outputs.tf)**: Complete list of available name outputs
- **[variables.tf](./variables.tf)**: Input variable validation rules

## Migration from Previous Version

If upgrading from the tier-based version:

### 1. Update environment codes

```hcl
# Before
environment = "nprd"

# After
environment = "np"
```

### 2. Remove tier variables

```hcl
# Before
validation_tier         = "moderate"
developer_suffix_buffer = 6

# After (not needed - these variables removed)
```

### 3. Update outputs (optional)

```hcl
# Before: Used specific name outputs
name = module.naming.name.alb

# After: Use clean name (recommended)
name = module.naming.name

# Or: Use optional suffix output (backwards compat)
name = module.naming.name_with_suffix.alb
```

## Why This Approach?

**Research Findings**:
- AWS recommends simplifying names and using tags for metadata
- ARNs already contain resource type information
- Terraform resource types clearly identify resource kind
- "Use 50 tags rather than too few" - AWS best practices
- Shorter names = fewer validation issues

**Benefits**:
- ✅ Shorter names (saves 6-10 characters per resource)
- ✅ Simpler validation (one 32-char limit vs. complex tier system)
- ✅ Aligned with AWS official guidance
- ✅ Easier to read and understand
- ✅ Flexible (add suffixes only when needed)

## Examples

### Governance Layer

```hcl
module "governance" {
  source = "..."

  product     = "whub"
  environment = "p"
  application = "observability"
  repository  = "winehub-governance"
  layer       = "governance"
  criticality = "high"
  backup      = "tier-1"
}
```

### Shared Infrastructure

```hcl
module "network" {
  source = "..."

  product     = "whub"
  environment = "p"
  application = "networking"
  repository  = "winehub-network"
  layer       = "shared-infrastructure"
  criticality = "critical"
  backup      = "tier-1"
}
```

### Application Layer

```hcl
module "api" {
  source = "..."

  product     = "whub"
  environment = "np"
  application = "api"
  repository  = "winehub-api"
  layer       = "application"
  criticality = "medium"
  backup      = "tier-2"

  additional_tags = {
    Owner      = "platform-team"
    CostCenter = "engineering"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name (e.g., zoho-crm, analytics, api, observability)<br/><br/>Naming pattern: {product}-{env}-{app}<br/>Example: whub-np-observability (21 chars)<br/><br/>Recommended: Keep total prefix under 32 characters for ALB/NLB compatibility.<br/>With short environments (p, np, d, s), you have plenty of room for descriptive names.<br/><br/>Examples:<br/>- whub-p-api (10 chars) ✓<br/>- whub-p-analytics (16 chars) ✓<br/>- whub-np-observability (21 chars) ✓<br/>- whub-p-customer-portal (22 chars) ✓ | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code (p=production, pp=preprod, np=nonprod, s=staging, u=uat, t=test, d=development) | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | Git repository name (e.g., 'howards-folly-wine', 'agnostic-1'). Used for the Repository tag to track which codebase manages this infrastructure. | `string` | n/a | yes |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to merge with mandatory tags | `map(string)` | `{}` | no |
| <a name="input_backup"></a> [backup](#input\_backup) | Backup tier for retention policy | `string` | `"none"` | no |
| <a name="input_criticality"></a> [criticality](#input\_criticality) | Business criticality level for support prioritization | `string` | `"medium"` | no |
| <a name="input_layer"></a> [layer](#input\_layer) | Architecture layer designation | `string` | `"application"` | no |
| <a name="input_product"></a> [product](#input\_product) | Product prefix for resource naming (e.g., 'whub' for WineHub, 'prkr' for PerkRunner) | `string` | `"whub"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_tags"></a> [default\_tags](#output\_default\_tags) | Tags for AWS provider default\_tags block |
| <a name="output_environment_display"></a> [environment\_display](#output\_environment\_display) | Human-readable environment name |
| <a name="output_mandatory_tags"></a> [mandatory\_tags](#output\_mandatory\_tags) | All mandatory tags including Repository (for resource-level tags) |
| <a name="output_name"></a> [name](#output\_name) | Resource name without type suffix - use this for most resources. AWS tags identify the resource type. |
| <a name="output_name_tag"></a> [name\_tag](#output\_name\_tag) | Map of resource types requiring Name tags (for resources identified primarily by tags, like subnets and security groups) |
| <a name="output_name_with_suffix"></a> [name\_with\_suffix](#output\_name\_with\_suffix) | Optional: Resource names with type suffixes for backwards compatibility or disambiguation. Prefer using 'name' output directly - resource type is clear from Terraform resource type and tags. |
| <a name="output_prefix"></a> [prefix](#output\_prefix) | Base resource name prefix ({product}-{env}-{app}) |
| <a name="output_tags_with_name"></a> [tags\_with\_name](#output\_tags\_with\_name) | Helper: Returns mandatory tags merged with a Name tag for specific resource types (use with name\_tag map keys) |
<!-- END_TF_DOCS -->
