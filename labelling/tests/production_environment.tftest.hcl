# =============================================================================
# Production Environment Tests
# =============================================================================
# Simulates real-world production environment usage
# Tests production-specific configurations: critical criticality, tier-1 backup
# All production resources should have appropriate disaster recovery settings
# =============================================================================

# Mock AWS provider - no real AWS resources will be created
mock_provider "aws" {}

# =============================================================================
# Production: WineHub API (Critical Service)
# =============================================================================
run "production_winehub_api" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # Verify production prefix
  assert {
    condition     = output.prefix == "whub-p-api"
    error_message = "Production API prefix incorrect"
  }

  # Production must have correct environment tag
  assert {
    condition     = output.mandatory_tags.Environment == "production"
    error_message = "Environment tag should be 'production'"
  }

  # Production API is critical
  assert {
    condition     = output.mandatory_tags.Criticality == "critical"
    error_message = "Production API must have critical criticality"
  }

  # Production requires tier-1 backup
  assert {
    condition     = output.mandatory_tags.Backup == "tier-1"
    error_message = "Production critical services must have tier-1 backup"
  }

  # Verify ALB naming (production ALB handles customer traffic)
  assert {
    condition     = output.name_with_suffix.alb == "whub-p-api-alb"
    error_message = "Production ALB name incorrect"
  }

  # Verify target group naming
  assert {
    condition     = output.name_with_suffix.target_group == "whub-p-api-tg"
    error_message = "Production ALB target group name incorrect"
  }
}

# =============================================================================
# Production: RDS Database (Data Layer)
# =============================================================================
run "production_database" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "db-primary"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.prefix == "whub-p-db-primary"
    error_message = "Production database prefix incorrect"
  }

  # Production RDS instance
  assert {
    condition     = output.name_with_suffix.rds_instance == "whub-p-db-primary-rds"
    error_message = "Production RDS instance name incorrect"
  }

  # Aurora cluster for high availability
  assert {
    condition     = output.name_with_suffix.aurora_cluster == "whub-p-db-primary-aurora"
    error_message = "Production Aurora cluster name incorrect"
  }
}

# =============================================================================
# Production: ElastiCache (Caching Layer)
# =============================================================================
run "production_cache" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "redis-cache"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.name_with_suffix.elasticache_cluster == "whub-p-redis-cache-redis"
    error_message = "Production Redis cluster name incorrect"
  }
}

# =============================================================================
# Production: S3 Data Lake
# =============================================================================
run "production_data_lake" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "data-lake"
    criticality = "high"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # S3 bucket names (globally unique, lowercase only)
  assert {
    condition     = output.name_with_suffix.s3_bucket == "whub-p-data-lake"
    error_message = "Production data lake bucket name incorrect"
  }

  # Verify lowercase for S3
  assert {
    condition     = output.name_with_suffix.s3_bucket == lower(output.name_with_suffix.s3_bucket)
    error_message = "S3 bucket name must be lowercase"
  }
}

# =============================================================================
# Production: Customer Portal (Frontend)
# =============================================================================
run "production_customer_portal" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "portal"
    criticality = "critical"
    backup      = "none" # Frontend assets don't need backup (stored in git)
    layer       = "application"
    repository  = "test-repo"
  }

  # CloudFront for global CDN
  assert {
    condition     = output.name_with_suffix.cloudfront_distribution == "whub-p-portal-cdn"
    error_message = "Production CloudFront distribution name incorrect"
  }

  # WAF for DDoS protection
  assert {
    condition     = output.name_with_suffix.waf_web_acl == "whub-p-portal-waf"
    error_message = "Production WAF ACL name incorrect"
  }

  # S3 for static assets
  assert {
    condition     = output.name_with_suffix.s3_bucket == "whub-p-portal"
    error_message = "Production portal bucket name incorrect"
  }
}

# =============================================================================
# Production: Shared VPC Infrastructure
# =============================================================================
run "production_vpc" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "network"
    criticality = "critical"
    backup      = "none"
    layer       = "shared-infrastructure"
    repository  = "test-repo"
  }

  # VPC resources use Name tags
  assert {
    condition     = output.name_tag.vpc == "whub-p-network-vpc"
    error_message = "Production VPC name tag incorrect"
  }

  # Multi-AZ NAT gateways
  assert {
    condition     = output.name_tag.nat_gateway == "whub-p-network-nat"
    error_message = "Production NAT gateway name tag incorrect"
  }

  # Internet gateway
  assert {
    condition     = output.name_tag.internet_gateway == "whub-p-network-igw"
    error_message = "Production IGW name tag incorrect"
  }

  # Route tables
  assert {
    condition     = output.name_tag.route_table_public == "whub-p-network-rt-public"
    error_message = "Production public route table name tag incorrect"
  }

  assert {
    condition     = output.name_tag.route_table_private == "whub-p-network-rt-private"
    error_message = "Production private route table name tag incorrect"
  }

  # Security groups
  assert {
    condition     = output.name_tag.security_group_alb == "whub-p-network-alb-sg"
    error_message = "Production ALB security group name tag incorrect"
  }

  assert {
    condition     = output.name_tag.security_group_rds == "whub-p-network-rds-sg"
    error_message = "Production RDS security group name tag incorrect"
  }
}

# =============================================================================
# Production: ECS Cluster (Container Orchestration)
# =============================================================================
run "production_ecs" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "containers"
    criticality = "critical"
    backup      = "none"
    layer       = "application"
    repository  = "test-repo"
  }

  # ECS cluster
  assert {
    condition     = output.name_with_suffix.ecs_cluster == "whub-p-containers-ecs"
    error_message = "Production ECS cluster name incorrect"
  }

  # ECS service naming
  assert {
    condition     = output.name_with_suffix.ecs_service == "whub-p-containers-svc"
    error_message = "Production ECS service name incorrect"
  }

  # ECS task definition
  assert {
    condition     = output.name_with_suffix.ecs_task_definition == "whub-p-containers-task"
    error_message = "Production ECS task definition name incorrect"
  }

  # IAM roles for ECS
  assert {
    condition     = output.name_with_suffix.ecs_task_execution_role == "whub-p-containers-ecs-exec-role"
    error_message = "Production ECS task execution role name incorrect"
  }

  assert {
    condition     = output.name_with_suffix.ecs_task_role == "whub-p-containers-ecs-task-role"
    error_message = "Production ECS task role name incorrect"
  }
}

# =============================================================================
# Production: Lambda Functions (Serverless)
# =============================================================================
run "production_lambda" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "webhook-proc"
    criticality = "critical"
    backup      = "none"
    layer       = "application"
    repository  = "test-repo"
  }

  # Lambda function
  assert {
    condition     = output.name_with_suffix.lambda == "whub-p-webhook-proc-lambda"
    error_message = "Production Lambda function name incorrect"
  }

  # Lambda IAM role
  assert {
    condition     = output.name_with_suffix.lambda_role == "whub-p-webhook-proc-lambda-role"
    error_message = "Production Lambda role name incorrect"
  }

  # Lambda layer
  assert {
    condition     = output.name_with_suffix.lambda_layer == "whub-p-webhook-proc-layer"
    error_message = "Production Lambda layer name incorrect"
  }

  # CloudWatch logs for Lambda
  assert {
    condition     = output.name_with_suffix.log_group_lambda == "/aws/lambda/whub-p-webhook-proc"
    error_message = "Production Lambda log group name incorrect"
  }
}

# =============================================================================
# Production: SQS Queues (Message Processing)
# =============================================================================
run "production_queues" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "orders"
    criticality = "critical"
    backup      = "none"
    layer       = "application"
    repository  = "test-repo"
  }

  # Standard queue
  assert {
    condition     = output.name_with_suffix.sqs_queue == "whub-p-orders-queue"
    error_message = "Production SQS queue name incorrect"
  }

  # Dead letter queue
  assert {
    condition     = output.name_with_suffix.sqs_queue_dlq == "whub-p-orders-dlq"
    error_message = "Production DLQ name incorrect"
  }

  # FIFO queue
  assert {
    condition     = output.name_with_suffix.sqs_queue_fifo == "whub-p-orders-queue.fifo"
    error_message = "Production FIFO queue name incorrect"
  }

  # Verify FIFO suffix
  assert {
    condition     = can(regex("\\.fifo$", output.name_with_suffix.sqs_queue_fifo))
    error_message = "Production FIFO queue must end with .fifo"
  }
}

# =============================================================================
# Production: Secrets Manager
# =============================================================================
run "production_secrets" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "app-secrets"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  # Secrets Manager naming
  assert {
    condition     = output.name_with_suffix.secret == "whub-p-app-secrets-secret"
    error_message = "Production secret name incorrect"
  }

  assert {
    condition     = output.name_with_suffix.secret_db_credentials == "whub-p-app-secrets/db/credentials"
    error_message = "Production DB credentials secret path incorrect"
  }

  assert {
    condition     = output.name_with_suffix.secret_api_key == "whub-p-app-secrets/api/key"
    error_message = "Production API key secret path incorrect"
  }

  # SSM Parameter Store
  assert {
    condition     = output.name_with_suffix.ssm_parameter == "/whub-p-app-secrets"
    error_message = "Production SSM parameter path incorrect"
  }
}

# =============================================================================
# Production: Non-Production Environment (nprd)
# =============================================================================
run "non_production_testing" {
  command = plan

  variables {
    product     = "whub"
    environment = "np"
    application = "qa-testing"
    criticality = "medium"
    backup      = "tier-2"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.prefix == "whub-np-qa-testing"
    error_message = "Non-production prefix incorrect"
  }

  assert {
    condition     = output.mandatory_tags.Environment == "nonprod"
    error_message = "Environment display should be 'nonprod'"
  }

  # NPRD should have lower backup tier
  assert {
    condition     = output.mandatory_tags.Backup == "tier-2"
    error_message = "Non-production should use tier-2 backup"
  }
}

# =============================================================================
# Production: PerkRunner Production
# =============================================================================
run "production_perkrunner" {
  command = plan

  variables {
    product     = "prkr"
    environment = "p"
    application = "api"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "application"
    repository  = "test-repo"
  }

  assert {
    condition     = output.prefix == "prkr-p-api"
    error_message = "PerkRunner production prefix incorrect"
  }

  # Verify product code
  assert {
    condition     = can(regex("^prkr-", output.prefix))
    error_message = "PerkRunner resources must start with 'prkr-'"
  }

  assert {
    condition     = output.mandatory_tags.Application == "api"
    error_message = "Application tag incorrect for PerkRunner"
  }
}

# =============================================================================
# Production: Governance Layer
# =============================================================================
run "production_governance" {
  command = plan

  variables {
    product     = "whub"
    environment = "p"
    application = "audit-logs"
    criticality = "critical"
    backup      = "tier-1"
    layer       = "governance"
    repository  = "test-repo"
  }

  assert {
    condition     = output.mandatory_tags.Layer == "governance"
    error_message = "Layer should be 'governance'"
  }

  # CloudWatch log groups for audit
  assert {
    condition     = output.name_with_suffix.log_group == "/aws/whub-p-audit-logs"
    error_message = "Audit log group name incorrect"
  }

  # S3 for audit trail
  assert {
    condition     = output.name_with_suffix.s3_bucket == "whub-p-audit-logs"
    error_message = "Audit logs bucket name incorrect"
  }
}
