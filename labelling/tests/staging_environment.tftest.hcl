# =============================================================================
# Staging Environment Tests
# =============================================================================
# Simulates real-world staging environment usage with typical application names
# Tests the labelling module as it would be used in actual staging infrastructure
# =============================================================================

# Mock AWS provider - no real AWS resources will be created
mock_provider "aws" {}

# =============================================================================
# Staging: WineHub API
# =============================================================================
run "staging_winehub_api" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "api"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
  }

  # Verify staging-specific configurations
  assert {
    condition     = output.prefix == "whub-stg-api"
    error_message = "Staging API prefix incorrect"
  }

  assert {
    condition     = output.mandatory_tags.Environment == "staging"
    error_message = "Environment tag should be 'staging'"
  }

  assert {
    condition     = output.mandatory_tags.Criticality == "high"
    error_message = "Staging API should have high criticality"
  }

  # Verify resource names are appropriate for staging
  assert {
    condition     = output.name.lambda == "whub-stg-api-lambda"
    error_message = "Lambda name for staging API incorrect"
  }

  assert {
    condition     = output.name.alb == "whub-stg-api-alb"
    error_message = "ALB name for staging API incorrect"
  }

  assert {
    condition     = output.name.ecs_cluster == "whub-stg-api-ecs"
    error_message = "ECS cluster name for staging API incorrect"
  }
}

# =============================================================================
# Staging: Analytics Platform
# =============================================================================
run "staging_analytics" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "analytics"
    criticality = "medium"
    backup      = "tier-2"
    layer       = "application"
  }

  assert {
    condition     = output.prefix == "whub-stg-analytics"
    error_message = "Staging analytics prefix incorrect"
  }

  # Verify RDS naming for analytics database
  assert {
    condition     = output.name.rds_instance == "whub-stg-analytics-rds"
    error_message = "RDS instance name for staging analytics incorrect"
  }

  # Verify S3 bucket naming
  assert {
    condition     = output.name.s3_bucket == "whub-stg-analytics"
    error_message = "S3 bucket name for staging analytics incorrect"
  }

  # Analytics should have tier-2 backup
  assert {
    condition     = output.mandatory_tags.Backup == "tier-2"
    error_message = "Analytics backup tier should be tier-2"
  }
}

# =============================================================================
# Staging: Zoho CRM Integration
# =============================================================================
run "staging_zoho_crm" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "zoho-crm"
    criticality = "medium"
    backup      = "tier-1"
    layer       = "application"
  }

  assert {
    condition     = output.prefix == "whub-stg-zoho-crm"
    error_message = "Staging Zoho CRM prefix incorrect"
  }

  # Lambda names for integration
  assert {
    condition     = output.name.lambda == "whub-stg-zoho-crm-lambda"
    error_message = "Lambda name for Zoho CRM integration incorrect"
  }

  # SQS queues for async processing
  assert {
    condition     = output.name.sqs_queue == "whub-stg-zoho-crm-queue"
    error_message = "SQS queue name for Zoho CRM incorrect"
  }

  assert {
    condition     = output.name.sqs_queue_dlq == "whub-stg-zoho-crm-dlq"
    error_message = "DLQ name for Zoho CRM incorrect"
  }
}

# =============================================================================
# Staging: Customer Portal
# =============================================================================
run "staging_customer_portal" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "cust-portal"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
  }

  assert {
    condition     = output.prefix == "whub-stg-cust-portal"
    error_message = "Staging customer portal prefix incorrect"
  }

  # Frontend resources
  assert {
    condition     = output.name.s3_bucket == "whub-stg-cust-portal"
    error_message = "S3 bucket for customer portal incorrect"
  }

  assert {
    condition     = output.name.cloudfront_distribution == "whub-stg-cust-portal-cdn"
    error_message = "CloudFront distribution name incorrect"
  }

  # ALB for backend API
  assert {
    condition     = output.name.alb == "whub-stg-cust-portal-alb"
    error_message = "ALB name for customer portal backend incorrect"
  }
}

# =============================================================================
# Staging: Shared Infrastructure
# =============================================================================
run "staging_shared_infra" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "vpc-network"
    criticality = "critical"
    backup      = "none"
    layer       = "shared-infrastructure"
  }

  assert {
    condition     = output.mandatory_tags.Layer == "shared-infrastructure"
    error_message = "Layer should be 'shared-infrastructure'"
  }

  # VPC and networking resources
  assert {
    condition     = output.name_tag.vpc == "whub-stg-vpc-network-vpc"
    error_message = "VPC name tag incorrect"
  }

  assert {
    condition     = output.name_tag.nat_gateway == "whub-stg-vpc-network-nat-stg"
    error_message = "NAT gateway name tag incorrect"
  }

  # Security groups
  assert {
    condition     = output.name_tag.security_group_alb == "whub-stg-vpc-network-alb-sg"
    error_message = "ALB security group name tag incorrect"
  }
}

# =============================================================================
# Staging: PerkRunner Benefits
# =============================================================================
run "staging_perkrunner_benefits" {
  command = plan

  variables {
    product     = "prkr"
    environment = "stg"
    application = "benefits"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
  }

  assert {
    condition     = output.prefix == "prkr-stg-benefits"
    error_message = "PerkRunner staging benefits prefix incorrect"
  }

  # Verify product code is correct
  assert {
    condition     = can(regex("^prkr-", output.prefix))
    error_message = "Prefix should start with 'prkr-' for PerkRunner"
  }

  assert {
    condition     = output.mandatory_tags.Application == "benefits"
    error_message = "Application tag should be 'benefits'"
  }
}

# =============================================================================
# Staging: Development Environment (whub-dev)
# =============================================================================
run "development_testing" {
  command = plan

  variables {
    product     = "whub"
    environment = "dev"
    application = "feature-test"
    criticality = "low"
    backup      = "none"
    layer       = "application"
  }

  assert {
    condition     = output.prefix == "whub-dev-feature-test"
    error_message = "Development prefix incorrect"
  }

  assert {
    condition     = output.mandatory_tags.Environment == "development"
    error_message = "Environment display should be 'development'"
  }

  assert {
    condition     = output.mandatory_tags.Criticality == "low"
    error_message = "Development features should have low criticality"
  }

  assert {
    condition     = output.mandatory_tags.Backup == "none"
    error_message = "Development features should have no backup"
  }
}

# =============================================================================
# Staging: Webhook Processing
# =============================================================================
run "staging_webhooks" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "webhooks"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
  }

  # SQS queues for webhook processing
  assert {
    condition     = output.name.sqs_queue == "whub-stg-webhooks-queue"
    error_message = "Webhook queue name incorrect"
  }

  assert {
    condition     = output.name.sqs_queue_high_priority == "whub-stg-webhooks-priority-queue"
    error_message = "High priority webhook queue name incorrect"
  }

  # Lambda for webhook processing
  assert {
    condition     = output.name.lambda == "whub-stg-webhooks-lambda"
    error_message = "Webhook Lambda name incorrect"
  }

  # DynamoDB for webhook state
  assert {
    condition     = output.name.dynamodb_table == "whub-stg-webhooks-table"
    error_message = "DynamoDB table name for webhooks incorrect"
  }
}

# =============================================================================
# Staging: Monitoring & Observability
# =============================================================================
run "staging_observability" {
  command = plan

  variables {
    product     = "whub"
    environment = "stg"
    application = "monitoring"
    criticality = "medium"
    backup      = "none"
    layer       = "shared-infrastructure"
  }

  # CloudWatch resources
  assert {
    condition     = output.name.log_group == "/aws/whub-stg-monitoring"
    error_message = "CloudWatch log group name incorrect"
  }

  assert {
    condition     = output.name.dashboard == "whub-stg-monitoring-dashboard"
    error_message = "CloudWatch dashboard name incorrect"
  }

  # EventBridge for event routing
  assert {
    condition     = output.name.eventbridge_rule == "whub-stg-monitoring-rule"
    error_message = "EventBridge rule name incorrect"
  }
}
