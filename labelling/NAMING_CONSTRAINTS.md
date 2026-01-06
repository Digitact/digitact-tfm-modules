# AWS Resource Naming Constraints & Validation

This document provides comprehensive information about AWS resource naming constraints and how the labelling module ensures compliance with a simplified, tag-based approach.

## Overview

The labelling module implements a **simplified naming strategy** that:
1. **Complies with AWS service-specific character limits**
2. **Follows AWS naming conventions** (allowed characters, pattern requirements)
3. **Uses tags to identify resource type** instead of name suffixes
4. **Keeps names short and readable** with abbreviated environments

## Naming Philosophy: Tags Over Suffixes

**AWS Recommendation**: Simplify resource names and use tags for metadata and resource identification.

**Why This Approach?**
- AWS allows 50 tags per resource - use them for rich metadata
- ARNs already contain resource type information
- Terraform resource types clearly identify what each resource is
- Shorter names = fewer validation issues

**Example:**
```hcl
# Old approach: whub-nprd-observability-alb (27 chars)
# New approach: whub-np-observability (21 chars)
resource "aws_lb" "main" {
  name = module.naming.name  # ← Resource type is "aws_lb"
  tags = module.naming.mandatory_tags  # ← Tags include Application, Environment, etc.
}
```

## Naming Formula

All resource names follow this simplified pattern:

```
{product}-{environment}-{application}
```

**Example:** `whub-np-observability`

- `product`: 3-8 characters (e.g., `whub`, `prkr`)
- `environment`: 1-2 characters (`p`, `pp`, `np`, `s`, `u`, `t`, `d`)
- `application`: 3-26 characters (e.g., `api`, `zoho-crm`, `observability`)

### Environment Codes

| Code | Environment | Example |
|------|-------------|---------|
| `p` | production | `whub-p-api` |
| `pp` | preprod | `whub-pp-api` |
| `np` | nonprod | `whub-np-observability` |
| `s` | staging | `whub-s-analytics` |
| `u` | uat | `whub-u-testing` |
| `t` | test | `whub-t-experiment` |
| `d` | development | `whub-d-prototype` |

### Backwards Compatibility

For teams migrating from suffix-based naming, the module provides optional suffixed names:

```hcl
# Recommended: Use the clean name
resource "aws_lb" "main" {
  name = module.naming.name  # whub-np-observability
}

# Backwards compatibility: Use optional suffix
resource "aws_lb" "main" {
  name = module.naming.name_with_suffix.alb  # whub-np-observability-alb
}
```

## Critical Constraints

### Validation Limit: 32 Characters

The module validates that your prefix stays under **32 characters** - the AWS limit for ALB/NLB resources.

**Calculation:**
```
Product (4) + Hyphen (1) + Environment (2) + Hyphen (1) + Application (24)
= Maximum 32 characters
```

**Example Valid Prefixes:**
- `whub-p-api` (10 chars) ✅
- `whub-p-analytics` (16 chars) ✅
- `whub-np-observability` (21 chars) ✅ ← Original blocker SOLVED!
- `whub-p-customer-portal` (22 chars) ✅

**Example Invalid Prefixes:**
- `whub-np-very-long-application-name` (35 chars) ❌ Exceeds 32-char limit
- `digitact-production-application` (32 chars) ❌ Old environment codes too long

### Most Restrictive Resources

These resources have the tightest naming constraints:

| Resource Type | AWS Limit | Max Application Name* |
|---------------|-----------|----------------------|
| **ALB/NLB** | 32 chars | 24 chars (with `whub-np-`) |
| **Target Group** | 32 chars | 24 chars (with `whub-np-`) |
| **RDS Instance** | 63 chars | 55 chars (plenty of room) |
| **Lambda Function** | 64 chars | 56 chars (plenty of room) |
| **S3 Bucket** | 63 chars | 55 chars (plenty of room) |
| **SQS Queue** | 80 chars | 72 chars (plenty of room) |

*Assuming `whub-np-` prefix (8 chars). Adjust for your product/environment codes.

## AWS Service-Specific Rules

### S3 Buckets

**Constraints:**
- 3-63 characters
- **Lowercase only** (no uppercase letters)
- Letters, numbers, hyphens
- Must begin and end with letter or number
- **Globally unique** across all AWS accounts

**Module Validation:**
- Ensures prefix contains only lowercase letters, numbers, and hyphens
- Developer must append account ID or region for uniqueness

**Example:**
```hcl
# Module generates: whub-p-analytics
# Developer adds account ID for S3 global uniqueness:
resource "aws_s3_bucket" "artifacts" {
  bucket = "${module.naming.name}-artifacts-123456789012"
  tags   = module.naming.mandatory_tags
}
```

### RDS & Aurora

**Constraints:**
- 1-63 alphanumeric characters or hyphens
- Must begin with a letter
- Cannot end with hyphen
- Cannot contain consecutive hyphens
- Must be unique per AWS account per region

**Module Validation:**
- Prevents consecutive hyphens in application name
- Ensures prefix doesn't start/end with hyphen
- Validates lowercase only

**Example:**
```hcl
# whub-p-analytics (16 chars < 63)
resource "aws_rds_cluster" "main" {
  cluster_identifier = module.naming.name
  tags               = module.naming.mandatory_tags
}

# Optional: Add suffix for disambiguation
resource "aws_rds_cluster_instance" "primary" {
  identifier = "${module.naming.name}-primary"  # whub-p-analytics-primary
}
```

### IAM Roles

**Constraints:**
- **64 characters maximum**
- Alphanumeric plus: `+ = , . @ - _`

**Module Validation:**
- Prefix validation ensures role names fit within 64-char limit
- Plenty of room for descriptive suffixes

**Example:**
```hcl
# whub-p-api (10 chars) leaves room for descriptive suffix
resource "aws_iam_role" "ecs_task" {
  name = "${module.naming.name}-ecs-task-role"  # whub-p-api-ecs-task-role (24 chars)
  tags = module.naming.mandatory_tags
}

# Or use the optional suffix output
resource "aws_iam_role" "lambda" {
  name = module.naming.name_with_suffix.lambda_role  # whub-p-api-lambda-role
  tags = module.naming.mandatory_tags
}
```

### Application Load Balancer (ALB) / Network Load Balancer (NLB)

**Constraints:**
- **32 characters maximum**
- Alphanumeric and hyphens only
- Must begin and end with alphanumeric

**Module Validation:**
- Primary driver of 32-char validation limit
- Strictest constraint in the module

**Example:**
```hcl
# whub-p-api (10 chars < 32) ✅
resource "aws_lb" "main" {
  name = module.naming.name
  tags = module.naming.mandatory_tags
}

# whub-np-observability (21 chars < 32) ✅
resource "aws_lb" "monitoring" {
  name = module.naming.name
  tags = module.naming.mandatory_tags
}
```

### Lambda Functions

**Constraints:**
- 1-64 characters
- Alphanumeric, hyphens, underscores
- Case sensitive

**Module Validation:**
- Prefix limit ensures all Lambda-related names fit
- Can add descriptive suffixes as needed

**Example:**
```hcl
# whub-p-api (10 chars < 64) ✅
resource "aws_lambda_function" "api" {
  function_name = module.naming.name
  tags          = module.naming.mandatory_tags
}

# Add suffix for specific handler
resource "aws_lambda_function" "webhook" {
  function_name = "${module.naming.name}-webhook"  # whub-p-api-webhook
  tags          = module.naming.mandatory_tags
}
```

### SQS Queues

**Constraints:**
- 1-80 characters
- Alphanumeric, hyphens, underscores
- **FIFO queues must end with `.fifo`**

**Module Validation:**
- Very lenient due to 80-char limit

**Example:**
```hcl
# whub-p-orders (13 chars < 80) ✅
resource "aws_sqs_queue" "standard" {
  name = module.naming.name
  tags = module.naming.mandatory_tags
}

# FIFO with suffix
resource "aws_sqs_queue" "fifo" {
  name       = "${module.naming.name}.fifo"  # whub-p-orders.fifo
  fifo_queue = true
  tags       = module.naming.mandatory_tags
}
```

### ECS Clusters & Services

**Constraints:**
- Up to 255 characters
- Alphanumeric, hyphens, underscores

**Module Validation:**
- Very permissive due to generous limit
- No special constraints needed

**Example:**
```hcl
resource "aws_ecs_cluster" "main" {
  name = module.naming.name  # whub-p-api
  tags = module.naming.mandatory_tags
}
```

### CloudWatch Log Groups

**Constraints:**
- Up to 512 characters
- Pattern: `/aws/{service}/{name}` or `/application/{name}`

**Module Validation:**
- No length concerns
- Module provides pre-formatted paths via `name_with_suffix` output

**Example:**
```hcl
# Using module output
resource "aws_cloudwatch_log_group" "lambda" {
  name = module.naming.name_with_suffix.log_group_lambda  # /aws/lambda/whub-p-api
  tags = module.naming.mandatory_tags
}

# Custom path
resource "aws_cloudwatch_log_group" "custom" {
  name = "/application/${module.naming.name}/errors"  # /application/whub-p-api/errors
  tags = module.naming.mandatory_tags
}
```

## Terraform Validation Checks

The module includes automated validation checks that will **fail at plan time** if constraints are violated:

### Check 1: Prefix Length (32 chars)

```hcl
check "prefix_length_validation" {
  assert {
    condition     = local.prefix_length <= 32
    error_message = <<-EOT
      Naming prefix exceeds 32-character limit for ALB/NLB compatibility.

      Current: {product}-{environment}-{application}

      Solutions:
      1. Shorten application name
      2. Use shorter product code
      3. Ensure using short environment codes (p, pp, np, s, u, t, d)
    EOT
  }
}
```

### Check 2: S3 Lowercase Requirement

```hcl
check "s3_naming_validation" {
  assert {
    condition     = can(regex("^[a-z0-9-]+$", local.prefix))
    error_message = "S3 bucket names require lowercase letters only"
  }
}
```

### Check 3: No Leading/Trailing Hyphens

```hcl
check "hyphen_placement_validation" {
  assert {
    condition     = !can(regex("^-|-$", local.prefix))
    error_message = "Names cannot start or end with hyphen (RDS/S3/ALB requirement)"
  }
}
```

### Check 4: No Consecutive Hyphens

```hcl
check "consecutive_hyphens_validation" {
  assert {
    condition     = !can(regex("--", local.prefix))
    error_message = "Names cannot contain consecutive hyphens (RDS requirement)"
  }
}
```

## Resource Identification Without Suffixes

**How to identify resource types without `-alb`, `-lambda` suffixes:**

1. **Terraform Resource Type**: `resource "aws_lb"` clearly shows it's a load balancer
2. **AWS Tags**: `Application`, `Environment`, `ManagedBy`, `Layer` tags provide metadata
3. **AWS Console**: Resource type is obvious in the UI
4. **ARN**: Contains resource type information
   ```
   arn:aws:elasticloadbalancing:ap-southeast-2:123456789012:loadbalancer/app/whub-p-api/abc123
                                                                              ^^^^^^^^^^^
   ```

**Tag-Based Filtering:**
```bash
# Find all ALBs for an application
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?Tags[?Key=='Application' && Value=='api']].LoadBalancerName"

# Find resources by environment
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Environment,Values=production
```

## Troubleshooting

### Error: "Prefix exceeds 32-character limit"

**Problem:** Your `{product}-{environment}-{application}` combination is too long.

**Solutions:**

1. **Shorten application name (recommended):**
   ```hcl
   # Before: whub-np-very-long-application (30 chars) ❌
   # After:  whub-np-long-app (17 chars) ✅

   application = "long-app"  # Instead of "very-long-application"
   ```

2. **Verify short environment codes:**
   ```hcl
   # Before: environment = "nprd" (nprd is 4 chars)
   # After:  environment = "np"   (np is 2 chars) ✅

   # Valid codes: p, pp, np, s, u, t, d
   ```

3. **Use abbreviations:**
   ```hcl
   application = "custport"    # Instead of "customer-portal"
   application = "analytics"   # Instead of "analytics-platform"
   application = "observ"      # Instead of "observability" (if desperate)
   ```

4. **Shorter product code:**
   ```hcl
   product = "wh"   # Instead of "whub" (saves 2 chars)
   ```

### Error: "Application contains consecutive hyphens"

**Problem:** Application name has `--` which violates AWS rules.

**Solution:**
```hcl
# Before: application = "my--app" ❌
# After:  application = "my-app"  ✅
```

### Error: "S3 bucket names require lowercase"

**Problem:** Variable contains uppercase letters.

**Solution:**
```hcl
# Before: application = "MyApp" ❌
# After:  application = "myapp" ✅
```

## Best Practices

### 1. Keep Application Names Descriptive but Concise

```hcl
# Good examples (short environments give you 24 chars for app name):
application = "api"                    # 3 chars
application = "web"                    # 3 chars
application = "analytics"              # 9 chars
application = "zoho-crm"              # 8 chars
application = "observability"         # 13 chars ✅ (solves original blocker!)
application = "customer-portal"       # 15 chars

# Still okay:
application = "data-warehouse"        # 14 chars
application = "payment-processing"    # 19 chars

# Getting tight (but valid):
application = "customer-relationship" # 21 chars (whub-np-customer-relationship = 30)
```

### 2. Use Consistent Abbreviations

Create a standard set of abbreviations across your organization:

```
customer    → cust
analytics   → analytics (keep readable)
dashboard   → dash
portal      → portal (keep readable)
integration → intg
service     → svc
management  → mgmt
```

**Prefer readability over extreme brevity** - with short environments, you have room for clear names.

### 3. Plan for Multi-Region and Uniqueness

Always append region or account ID to globally unique resources:

```hcl
# S3 buckets (globally unique)
resource "aws_s3_bucket" "data" {
  bucket = "${module.naming.name}-${data.aws_caller_identity.current.account_id}"
  # whub-p-analytics-123456789012
}

# ECR repositories (multi-region)
resource "aws_ecr_repository" "app" {
  name = "${module.naming.name}-${data.aws_region.current.name}"
  # whub-p-api-ap-southeast-2
}
```

### 4. Leverage Tags for Rich Metadata

Since names are simpler, use tags for additional context:

```hcl
module "naming" {
  source = "..."

  product     = "whub"
  environment = "p"
  application = "api"

  additional_tags = {
    Owner       = "platform-team"
    CostCenter  = "engineering"
    Project     = "core-infrastructure"
    Version     = "v2"
    Compliance  = "pci-dss"
  }
}

resource "aws_lb" "main" {
  name = module.naming.name  # Simple: whub-p-api
  tags = module.naming.mandatory_tags  # Rich metadata in tags
}
```

### 5. Document Disambiguation When Needed

For multiple resources of the same type, add clear suffixes:

```hcl
# Multiple ALBs for the same application
resource "aws_lb" "external" {
  name = "${module.naming.name}-ext"  # whub-p-api-ext
}

resource "aws_lb" "internal" {
  name = "${module.naming.name}-int"  # whub-p-api-int
}

# Blue/green deployments
resource "aws_lb" "blue" {
  name = "${module.naming.name}-blue"  # whub-p-api-blue
}

resource "aws_lb" "green" {
  name = "${module.naming.name}-green"  # whub-p-api-green
}
```

## Reference: Common Naming Patterns

### Single Resource Per Type
```hcl
# Clean and simple - recommended for most cases
resource "aws_lb" "main" {
  name = module.naming.name  # whub-p-api
}

resource "aws_lambda_function" "main" {
  function_name = module.naming.name  # whub-p-api
}
```

### Multiple Resources of Same Type
```hcl
# Add descriptive suffix for disambiguation
resource "aws_lambda_function" "webhook" {
  function_name = "${module.naming.name}-webhook"  # whub-p-api-webhook
}

resource "aws_lambda_function" "processor" {
  function_name = "${module.naming.name}-processor"  # whub-p-api-processor
}
```

### Resources Requiring Global Uniqueness
```hcl
# S3: Append account ID
resource "aws_s3_bucket" "artifacts" {
  bucket = "${module.naming.name}-${data.aws_caller_identity.current.account_id}"
  # whub-p-api-123456789012
}

# ECR: Append region for multi-region
resource "aws_ecr_repository" "app" {
  name = "${module.naming.name}-${var.region}"
  # whub-p-api-us-east-1
}
```

### Backwards Compatibility
```hcl
# Use optional suffix outputs during migration
resource "aws_lb" "main" {
  name = module.naming.name_with_suffix.alb  # whub-p-api-alb
}

# Gradually migrate to clean names
resource "aws_lb" "main" {
  name = module.naming.name  # whub-p-api
}
```

## Reference: All Naming Limits

| Resource | AWS Limit | Example (whub-np-) | Room for App Name |
|----------|-----------|-------------------|-------------------|
| ALB/NLB | 32 | `whub-np-` (8) | 24 chars |
| Target Group | 32 | `whub-np-` (8) | 24 chars |
| IAM Role | 64 | `whub-np-` (8) | 56 chars |
| IAM Policy | 128 | `whub-np-` (8) | 120 chars |
| RDS Instance | 63 | `whub-np-` (8) | 55 chars |
| S3 Bucket | 63 | `whub-np-` (8) | 55 chars |
| Lambda Function | 64 | `whub-np-` (8) | 56 chars |
| SQS Queue | 80 | `whub-np-` (8) | 72 chars |
| DynamoDB Table | 255 | `whub-np-` (8) | 247 chars |
| ECS Cluster | 255 | `whub-np-` (8) | 247 chars |
| CloudWatch Log | 512 | `whub-np-` (8) | 504 chars |

## Summary

The labelling module ensures all generated names:
- ✅ Comply with AWS service-specific character limits (32-char validation)
- ✅ Use only allowed characters for each resource type
- ✅ Follow simplified naming: `{product}-{env}-{application}`
- ✅ Use short environment codes (p, pp, np, s, u, t, d) for character efficiency
- ✅ Rely on tags and Terraform resource types for resource identification
- ✅ Validate at Terraform plan time to catch errors early
- ✅ Provide optional backwards-compatible suffixed names

**Key Change from Previous Version:**
- **Removed**: Complex tier system, resource type suffixes, developer buffer
- **Added**: Tag-based resource identification, short environment codes, 32-char validation
- **Result**: Simpler, clearer, aligned with AWS best practices

For questions or issues, refer to:
- [AWS Tagging Best Practices (Official)](https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/tagging-best-practices.html)
- [AWS Service Quotas Documentation](https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html)
- [IAM Naming Constraints](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html)
- [S3 Bucket Naming Rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
- [RDS Naming Constraints](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html)
