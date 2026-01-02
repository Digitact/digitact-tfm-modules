# AWS Resource Naming Constraints & Validation

This document provides comprehensive information about AWS resource naming constraints and how the labelling module ensures compliance while reserving space for developer customization.

## Overview

The labelling module implements strict validations to ensure generated resource names:
1. **Comply with AWS service-specific character limits**
2. **Follow AWS naming conventions** (allowed characters, pattern requirements)
3. **Reserve 6 characters** for developer suffixes (e.g., `-abcde`, `-test1`)

## Naming Formula

All resource names follow this pattern:

```
{product}-{environment}-{application}-{resource-suffix}
```

**Example:** `whub-prd-analytics-alb`

- `product`: 3-8 characters (e.g., `whub`, `prkr`)
- `environment`: 3-4 characters (`prd`, `nprd`, `dev`, `stg`)
- `application`: 3-20 characters (e.g., `api`, `zoho-crm`, `analytics`)
- `resource-suffix`: Varies by resource type (e.g., `-alb`, `-lambda`, `-rds`)

## Critical Constraints

### Most Restrictive Resources

These resources have the tightest naming constraints and drive our validation rules:

| Resource Type | AWS Limit | Reserved for Dev | Module Suffix | Max Prefix Length |
|---------------|-----------|------------------|---------------|-------------------|
| **ALB/NLB** | 32 chars | 6 chars | 4 chars (`-alb`) | **22 chars** |
| **Target Group** | 32 chars | 6 chars | 8 chars (`-nlb-tg`) | **18 chars** |
| **IAM Role** | 64 chars | 6 chars | 20 chars (varies) | **38 chars** |
| **RDS Instance** | 63 chars | 6 chars | 13 chars (`-aurora-inst`) | **44 chars** |
| **S3 Bucket** | 63 chars | 6 chars | 10 chars (`-artifacts`) | **47 chars** |
| **Lambda Function** | 64 chars | 6 chars | 17 chars (`-lambda-permission`) | **41 chars** |
| **SQS Queue** | 80 chars | 6 chars | 24 chars (`-high-priority`) | **50 chars** |

### Validation Strategy

The module uses **22 characters** as the maximum safe prefix length, based on ALB/NLB constraints.

**Calculation:**
```
ALB Limit: 32 characters
- Resource suffix: 4 characters ("-alb")
- Developer buffer: 6 characters ("-abcde")
= Maximum prefix: 22 characters
```

**Example Valid Prefixes:**
- `whub-prd-api` (11 chars) ✅
- `whub-prd-analytics` (17 chars) ✅
- `whub-nprd-zoho-crm` (16 chars) ✅
- `prkr-stg-benefits` (17 chars) ✅

**Example Invalid Prefixes:**
- `whub-prd-customer-portal` (23 chars) ❌ Exceeds 22-char limit
- `digitact-prd-application` (25 chars) ❌ Exceeds 22-char limit

## AWS Service-Specific Rules

### S3 Buckets

**Constraints:**
- 3-63 characters
- **Lowercase only** (no uppercase letters)
- Letters, numbers, hyphens, periods
- Must begin and end with letter or number
- Cannot have consecutive periods
- Cannot be formatted as IP address
- **Globally unique** across all AWS accounts

**Module Validation:**
- Ensures prefix contains only lowercase letters, numbers, and hyphens
- No uppercase validation at variable level
- Developer must append account ID or region for uniqueness

**Example:**
```hcl
# Module generates: whub-prd-analytics-artifacts
# Developer adds account ID for uniqueness:
resource "aws_s3_bucket" "artifacts" {
  bucket = "${module.naming.name.s3_bucket_artifacts}-123456789012"
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
# Valid: whub-prd-analytics-aurora (24 chars + 6 buffer = 30 chars < 63)
resource "aws_rds_cluster" "main" {
  cluster_identifier = module.naming.name.aurora_cluster
  tags               = module.naming.mandatory_tags
}
```

### IAM Roles

**Constraints:**
- **64 characters maximum**
- Alphanumeric plus: `+ = , . @ - _`
- For Switch Role in AWS Console: **Path + RoleName combined ≤ 64 chars**

**Module Validation:**
- Prefix validation ensures role names fit within 64-char limit
- Longest role suffix: `-ecs-task-execution-role` (24 chars)

**Example:**
```hcl
# whub-prd-api-ecs-task-role (23 chars + 6 buffer = 29 chars < 64)
resource "aws_iam_role" "ecs_task" {
  name = module.naming.name.ecs_task_role
  tags = module.naming.mandatory_tags
}
```

### Application Load Balancer (ALB) / Network Load Balancer (NLB)

**Constraints:**
- **32 characters maximum**
- Alphanumeric and hyphens only
- Must begin and end with alphanumeric

**Module Validation:**
- Primary driver of 22-char prefix limit
- Strictest constraint in the module

**Example:**
```hcl
# whub-prd-api-alb (15 chars + 6 buffer = 21 chars < 32)
resource "aws_lb" "main" {
  name = module.naming.name.alb
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
- Longest suffix: `-lambda-permission` (17 chars)

**Example:**
```hcl
# whub-prd-api-lambda (18 chars + 6 buffer = 24 chars < 64)
resource "aws_lambda_function" "api" {
  function_name = module.naming.name.lambda
  tags          = module.naming.mandatory_tags
}
```

### SQS Queues

**Constraints:**
- 1-80 characters
- Alphanumeric, hyphens, underscores
- **FIFO queues must end with `.fifo`**

**Module Validation:**
- More lenient than other resources
- FIFO suffix automatically added by module

**Example:**
```hcl
# whub-prd-orders-queue.fifo (24 chars + 6 buffer = 30 chars < 80)
resource "aws_sqs_queue" "fifo" {
  name       = module.naming.name.sqs_queue_fifo
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

### CloudWatch Log Groups

**Constraints:**
- Up to 512 characters
- Pattern: `/aws/{service}/{name}` or `/application/{name}`

**Module Validation:**
- No length concerns
- Module provides pre-formatted paths

**Example:**
```hcl
# /aws/lambda/whub-prd-api (<50 chars, plenty of room)
resource "aws_cloudwatch_log_group" "lambda" {
  name = module.naming.log_group_lambda
  tags = module.naming.mandatory_tags
}
```

## Terraform Validation Checks

The module includes automated validation checks that will **fail at plan time** if constraints are violated:

### Check 1: Prefix Length

```hcl
check "prefix_length_validation" {
  assert {
    condition     = local.prefix_length <= 22
    error_message = "Prefix exceeds 22-character limit for ALB/NLB compatibility"
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
    error_message = "Names cannot start or end with hyphen"
  }
}
```

### Check 4: No Consecutive Hyphens

```hcl
check "consecutive_hyphens_validation" {
  assert {
    condition     = !can(regex("--", local.prefix))
    error_message = "Names cannot contain consecutive hyphens"
  }
}
```

## Developer Suffix Reservation

The module reserves **6 characters** for developer-added suffixes. This enables:

### Use Case 1: Environment Variations

```hcl
# Production blue/green deployment
resource "aws_lb" "blue" {
  name = "${module.naming.name.alb}-blue"   # whub-prd-api-alb-blue
}

resource "aws_lb" "green" {
  name = "${module.naming.name.alb}-green"  # whub-prd-api-alb-green
}
```

### Use Case 2: Regional Resources

```hcl
# Multi-region S3 buckets
resource "aws_s3_bucket" "usw2" {
  bucket = "${module.naming.name.s3_bucket}-usw2-${data.aws_caller_identity.current.account_id}"
}
```

### Use Case 3: Feature Branches

```hcl
# Testing infrastructure
resource "aws_ecs_cluster" "test" {
  name = "${module.naming.name.ecs_cluster}-test1"  # whub-stg-api-ecs-test1
}
```

### Use Case 4: Versioning

```hcl
# API versions
resource "aws_lambda_function" "v2" {
  function_name = "${module.naming.name.lambda}-v2"  # whub-prd-api-lambda-v2
}
```

## Troubleshooting

### Error: "Prefix exceeds 22-character limit"

**Problem:** Your `{product}-{environment}-{application}` combination is too long.

**Solution:**
1. **Shorten application name:**
   ```hcl
   # Before: whub-prd-customer-portal (23 chars) ❌
   # After:  whub-prd-custport (17 chars) ✅

   application = "custport"  # Instead of "customer-portal"
   ```

2. **Use abbreviations:**
   ```hcl
   application = "zoho-crm"   # Instead of "zoho-crm-integration"
   application = "analytics"  # Instead of "analytics-platform"
   ```

3. **Shorter product code:**
   ```hcl
   product = "wh"   # Instead of "whub" (saves 2 chars)
   product = "pk"   # Instead of "prkr"
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

### 1. Keep Application Names Short

```hcl
# Good examples:
application = "api"
application = "web"
application = "analytics"
application = "zoho-crm"

# Avoid:
application = "customer-facing-portal"  # Too long
application = "internal-admin-dashboard"  # Too long
```

### 2. Use Consistent Abbreviations

Create a standard set of abbreviations across your organization:

```
customer    → cust
analytics   → anlytcs
dashboard   → dash
portal      → prtl
integration → intg
service     → svc
```

### 3. Plan for Multi-Region

Always append region or account ID to globally unique resources:

```hcl
resource "aws_s3_bucket" "data" {
  # Include account ID for uniqueness
  bucket = "${module.naming.name.s3_bucket}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_ecr_repository" "app" {
  # Include region for multi-region deployments
  name = "${module.naming.name.ecr_repository}-${data.aws_region.current.name}"
}
```

### 4. Document Resource-Specific Limits

For resources with special constraints (like Target Groups at 18-char prefix max), document this in your infrastructure code:

```hcl
# Target groups require prefix ≤ 18 chars
# Current prefix: whub-prd-api (12 chars) ✓
resource "aws_lb_target_group" "app" {
  name = module.naming.name.target_group_alb
}
```

## Reference: All Naming Limits

| Resource | AWS Limit | Reserved | Max Prefix | Allowed Characters |
|----------|-----------|----------|------------|-------------------|
| ALB/NLB | 32 | 6 | 22 | a-z, 0-9, - |
| Target Group | 32 | 6 | 18 | a-z, 0-9, - |
| IAM Role | 64 | 6 | 38 | a-z, A-Z, 0-9, +=,.@-_ |
| IAM User | 64 | 6 | 53 | a-z, A-Z, 0-9, +=,.@-_ |
| IAM Policy | 128 | 6 | 115 | a-z, A-Z, 0-9, +=,.@-_ |
| RDS Instance | 63 | 6 | 44 | a-z, 0-9, - |
| Aurora Cluster | 63 | 6 | 44 | a-z, 0-9, - |
| S3 Bucket | 63 | 6 | 47 | **a-z, 0-9, -, .** |
| Lambda Function | 64 | 6 | 41 | a-z, A-Z, 0-9, -, _ |
| SQS Queue | 80 | 6 | 50 | a-z, A-Z, 0-9, -, _ |
| DynamoDB Table | 255 | 6 | 230 | a-z, A-Z, 0-9, -, _, . |
| ECS Cluster | 255 | 6 | 230 | a-z, A-Z, 0-9, -, _ |
| Security Group | 255 | 6 | 236 | a-z, A-Z, 0-9, -, _ |
| CloudWatch Log Group | 512 | 6 | 476 | a-z, A-Z, 0-9, -, _, /, . |

## Summary

The labelling module ensures all generated names:
- ✅ Comply with AWS service-specific character limits
- ✅ Use only allowed characters for each resource type
- ✅ Reserve 6 characters for developer customization
- ✅ Follow consistent naming conventions
- ✅ Validate at Terraform plan time to catch errors early

For questions or issues, refer to:
- [AWS Service Quotas Documentation](https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html)
- [IAM Naming Constraints](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html)
- [S3 Bucket Naming Rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
- [RDS Naming Constraints](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html)
