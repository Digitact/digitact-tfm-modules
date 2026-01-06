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
    environment = "s"
    application = "api"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify staging-specific configurations
  assert {
    condition     = output.prefix == "whub-s-api"
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
    condition     = output.name_with_suffix.lambda == "whub-s-api-lambda"
    error_message = "Lambda name for staging API incorrect"
  }

  assert {
    condition     = output.name_with_suffix.alb == "whub-s-api-alb"
    error_message = "ALB name for staging API incorrect"
  }

  assert {
    condition     = output.name_with_suffix.ecs_cluster == "whub-s-api-ecs"
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
    environment = "s"
    application = "analytics"
    criticality = "medium"
    backup      = "tier-2"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.prefix == "whub-s-analytics"
    error_message = "Staging analytics prefix incorrect"
  }

  # Verify RDS naming for analytics database
  assert {
    condition     = output.name_with_suffix.rds_instance == "whub-s-analytics-rds"
    error_message = "RDS instance name for staging analytics incorrect"
  }

  # Verify S3 bucket naming
  assert {
    condition     = output.name_with_suffix.s3_bucket == "whub-s-analytics"
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
    environment = "s"
    application = "zoho-crm"
    criticality = "medium"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.prefix == "whub-s-zoho-crm"
    error_message = "Staging Zoho CRM prefix incorrect"
  }

  # Lambda names for integration
  assert {
    condition     = output.name_with_suffix.lambda == "whub-s-zoho-crm-lambda"
    error_message = "Lambda name for Zoho CRM integration incorrect"
  }

  # SQS queues for async processing
  assert {
    condition     = output.name_with_suffix.sqs_queue == "whub-s-zoho-crm-queue"
    error_message = "SQS queue name for Zoho CRM incorrect"
  }

  assert {
    condition     = output.name_with_suffix.sqs_queue_dlq == "whub-s-zoho-crm-dlq"
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
    environment = "s"
    application = "cust-portal"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.prefix == "whub-s-cust-portal"
    error_message = "Staging customer portal prefix incorrect"
  }

  # Frontend resources
  assert {
    condition     = output.name_with_suffix.s3_bucket == "whub-s-cust-portal"
    error_message = "S3 bucket for customer portal incorrect"
  }

  assert {
    condition     = output.name_with_suffix.cloudfront_distribution == "whub-s-cust-portal-cdn"
    error_message = "CloudFront distribution name incorrect"
  }

  # ALB for backend API
  assert {
    condition     = output.name_with_suffix.alb == "whub-s-cust-portal-alb"
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
    environment = "s"
    application = "vpc-network"
    criticality = "critical"
    backup      = "none"
    layer       = "shared-infrastructure"
    repository  = "test-repo"
  }

  assert {
    condition     = output.mandatory_tags.Layer == "shared-infrastructure"
    error_message = "Layer should be 'shared-infrastructure'"
  }

  # VPC and networking resources
  assert {
    condition     = output.name_tag.vpc == "whub-s-vpc-network-vpc"
    error_message = "VPC name tag incorrect"
  }

  assert {
    condition     = output.name_tag.nat_gateway == "whub-s-vpc-network-nat"
    error_message = "NAT gateway name tag incorrect"
  }

  # Security groups
  assert {
    condition     = output.name_tag.security_group_alb == "whub-s-vpc-network-alb-sg"
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
    environment = "s"
    application = "benefits"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.prefix == "prkr-s-benefits"
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
    environment = "d"
    application = "feature-test"
    criticality = "low"
    backup      = "none"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.prefix == "whub-d-feature-test"
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
    environment = "s"
    application = "webhooks"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # SQS queues for webhook processing
  assert {
    condition     = output.name_with_suffix.sqs_queue == "whub-s-webhooks-queue"
    error_message = "Webhook queue name incorrect"
  }

  # Lambda for webhook processing
  assert {
    condition     = output.name_with_suffix.lambda == "whub-s-webhooks-lambda"
    error_message = "Webhook Lambda name incorrect"
  }

  # DynamoDB for webhook state
  assert {
    condition     = output.name_with_suffix.dynamodb_table == "whub-s-webhooks-table"
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
    environment = "s"
    application = "monitoring"
    criticality = "medium"
    backup      = "none"
    layer       = "shared-infrastructure"
    repository  = "test-repo"
  }

  # CloudWatch resources
  assert {
    condition     = output.name_with_suffix.log_group == "/aws/whub-s-monitoring"
    error_message = "CloudWatch log group name incorrect"
  }

  assert {
    condition     = output.name_with_suffix.dashboard == "whub-s-monitoring-dashboard"
    error_message = "CloudWatch dashboard name incorrect"
  }

  # EventBridge for event routing
  assert {
    condition     = output.name_with_suffix.eventbridge_rule == "whub-s-monitoring-rule"
    error_message = "EventBridge rule name incorrect"
  }
}
