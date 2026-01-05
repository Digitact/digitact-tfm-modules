# Labelling Module - Usage Examples

This document provides comprehensive examples of how to use the `labelling` module for all resource types across your infrastructure.

> **📋 Important:** See [NAMING_CONSTRAINTS.md](./NAMING_CONSTRAINTS.md) for detailed information about:
> - AWS resource naming character limits
> - Validation rules and error messages
> - 6-character developer suffix reservation
> - Troubleshooting naming constraint errors

## Quick Start

```hcl
module "naming" {
  source = "./labelling"

  environment = "stg"
  application = "analytics"
  repository  = "analytics-service"
  criticality = "high"
  backup      = "tier-1"
  layer       = "application"
}
```

## Output Structure

The module provides 7 outputs:

1. **`prefix`** - Base name prefix: `whub-stg-analytics`
2. **`name`** - Map of resource names for resources with `name` argument
3. **`name_tag`** - Map of resource names for resources requiring `Name` tag
4. **`mandatory_tags`** - All 7 mandatory tags (including Repository)
5. **`tags_with_name`** - Mandatory tags + Name tag for specific resources
6. **`default_tags`** - Tags for AWS provider `default_tags` block
7. **`environment_display`** - Human-readable environment name

---

## Usage Patterns by Resource Type

### Pattern 1: Resources with `name` Argument

For resources that have a `name` argument (most AWS resources):

```hcl
# Lambda Function
resource "aws_lambda_function" "api" {
  function_name = module.naming.name.lambda
  tags          = module.naming.mandatory_tags
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = module.naming.name.ecs_cluster
  tags = module.naming.mandatory_tags
}

# S3 Bucket
resource "aws_s3_bucket" "artifacts" {
  bucket = module.naming.name.s3_bucket_artifacts
  tags   = module.naming.mandatory_tags
}

# IAM Role
resource "aws_iam_role" "ecs_task" {
  name = module.naming.name.ecs_task_role
  tags = module.naming.mandatory_tags
}
```

### Pattern 2: Resources Requiring `Name` Tag

For resources without `name` argument that use `Name` tag for identification:

```hcl
# VPC (uses Name tag, not name argument)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = module.naming.tags_with_name.vpc
  # This includes: Name, Application, Environment, Criticality, Backup, ManagedBy, Layer
}

# Subnet
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"
  tags              = module.naming.tags_with_name.subnet_public_1a
}

# Security Group (Name tag preferred for console visibility)
resource "aws_security_group" "alb" {
  name_prefix = "${module.naming.prefix}-alb-"  # Use name_prefix for uniqueness
  vpc_id      = aws_vpc.main.id
  tags        = module.naming.tags_with_name.security_group_alb
}

# EC2 Instance
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags          = module.naming.tags_with_name.ec2_bastion
}
```

### Pattern 3: Using AWS Provider `default_tags`

Set account-level default tags in provider configuration:

```hcl
provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = module.naming.default_tags
  }
}

# Now all resources automatically get the 6 mandatory tags
resource "aws_s3_bucket" "data" {
  bucket = module.naming.name.s3_bucket
  # Tags automatically applied via provider default_tags
}
```

---

## Complete Examples by Service

### VPC & Networking

```hcl
module "naming" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "web-api"
  criticality = "critical"
  backup      = "tier-1"
  layer       = "shared-infrastructure"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = module.naming.tags_with_name.vpc
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = module.naming.tags_with_name.internet_gateway
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = {
    "1a" = { cidr = "10.0.1.0/24", az = "ap-southeast-2a" }
    "1b" = { cidr = "10.0.2.0/24", az = "ap-southeast-2b" }
    "1c" = { cidr = "10.0.3.0/24", az = "ap-southeast-2c" }
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags                    = module.naming.tags_with_name["subnet_public_${each.key}"]
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = module.naming.tags_with_name.eip_nat
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["1a"].id
  tags          = module.naming.tags_with_name.nat_gateway
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = module.naming.tags_with_name.route_table_public

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Security Group
resource "aws_security_group" "alb" {
  name        = module.naming.name.security_group_alb
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id
  tags        = module.naming.tags_with_name.security_group_alb
}
```

### ECS Service

```hcl
module "naming" {
  source      = "./labelling"
  environment = "stg"
  repository  = "infrastructure-repo"
  application = "api"
  criticality = "high"
  backup      = "none"
  layer       = "application"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = module.naming.name.ecs_cluster
  tags = module.naming.mandatory_tags
}

# Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = module.naming.name.ecs_task_execution_role
  tags = module.naming.mandatory_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = module.naming.name.ecs_task_definition
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  tags                     = module.naming.mandatory_tags

  container_definitions = jsonencode([{
    name  = "app"
    image = "${module.naming.name.ecr_repository}:latest"
    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = "ap-southeast-2"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS Service
resource "aws_ecs_service" "api" {
  name            = module.naming.name.ecs_service
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  tags            = module.naming.mandatory_tags

  network_configuration {
    subnets          = [aws_subnet.private["1a"].id, aws_subnet.private["1b"].id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "app"
    container_port   = 8080
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = module.naming.name.log_group_ecs
  retention_in_days = 30
  tags              = module.naming.mandatory_tags
}
```

### RDS / Aurora Database

```hcl
module "naming" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "analytics-db"
  criticality = "critical"
  backup      = "tier-1"  # Automated backups enabled
  layer       = "application"
}

# DB Subnet Group
resource "aws_db_subnet_group" "aurora" {
  name       = module.naming.name.db_subnet_group
  subnet_ids = [aws_subnet.database["1a"].id, aws_subnet.database["1b"].id, aws_subnet.database["1c"].id]
  tags       = module.naming.mandatory_tags
}

# Aurora Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = module.naming.name.aurora_parameter_group
  family      = "aurora-postgresql14"
  description = "Aurora PostgreSQL 14 cluster parameter group"
  tags        = module.naming.mandatory_tags
}

# Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier              = module.naming.name.aurora_cluster
  engine                          = "aurora-postgresql"
  engine_version                  = "14.7"
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  backup_retention_period         = 30
  preferred_backup_window         = "03:00-04:00"
  preferred_maintenance_window    = "mon:04:00-mon:05:00"
  enabled_cloudwatch_logs_exports = ["postgresql"]
  tags                            = module.naming.mandatory_tags
}

# Aurora Instances
resource "aws_rds_cluster_instance" "main" {
  count              = 2
  identifier         = "${module.naming.name.aurora_instance}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  tags               = module.naming.mandatory_tags
}
```

### Lambda Function with Secrets

```hcl
module "naming" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "webhook-processor"
  criticality = "high"
  backup      = "none"
  layer       = "application"
}

# Secrets Manager Secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = module.naming.name.secret_db_credentials
  description = "Database credentials for webhook processor"
  tags        = module.naming.mandatory_tags
}

# Lambda Execution Role
resource "aws_iam_role" "lambda" {
  name = module.naming.name.lambda_role
  tags = module.naming.mandatory_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda Function
resource "aws_lambda_function" "webhook" {
  function_name = module.naming.name.lambda
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "lambda.zip"
  tags          = module.naming.mandatory_tags

  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
      ENVIRONMENT   = module.naming.environment_display
    }
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = module.naming.name.log_group_lambda
  retention_in_days = 14
  tags              = module.naming.mandatory_tags
}
```

### S3 Buckets with Lifecycle

```hcl
module "naming" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "data-lake"
  criticality = "medium"
  backup      = "tier-2"
  layer       = "application"
}

# Application Artifacts Bucket
resource "aws_s3_bucket" "artifacts" {
  bucket = module.naming.name.s3_bucket_artifacts
  tags   = module.naming.mandatory_tags
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Logs Bucket
resource "aws_s3_bucket" "logs" {
  bucket = module.naming.name.s3_bucket_logs
  tags   = module.naming.mandatory_tags
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
```

### SQS Queues with Dead Letter Queue

```hcl
module "naming" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "order-processing"
  criticality = "high"
  backup      = "none"
  layer       = "application"
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name                      = module.naming.name.sqs_queue_dlq
  message_retention_seconds = 1209600  # 14 days
  tags                      = module.naming.mandatory_tags
}

# Main Queue with DLQ
resource "aws_sqs_queue" "main" {
  name                       = module.naming.name.sqs_queue
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600  # 4 days
  receive_wait_time_seconds  = 10      # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = module.naming.mandatory_tags
}

# FIFO Queue (for ordered processing)
resource "aws_sqs_queue" "fifo" {
  name                        = module.naming.name.sqs_queue_fifo
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  tags                        = module.naming.mandatory_tags
}

# High Priority Queue
resource "aws_sqs_queue" "high_priority" {
  name                       = module.naming.name.sqs_queue_high_priority
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400   # 1 day
  tags                       = module.naming.mandatory_tags
}

# CloudWatch Alarms for Queue Monitoring
resource "aws_cloudwatch_metric_alarm" "queue_age" {
  alarm_name          = "${module.naming.prefix}-sqs-age-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 600  # 10 minutes

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  tags = module.naming.mandatory_tags
}
```

### Application Load Balancer

```hcl
module "naming" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "web"
  criticality = "critical"
  backup      = "none"
  layer       = "application"
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = module.naming.name.security_group_alb
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id
  tags        = module.naming.tags_with_name.security_group_alb

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = module.naming.name.alb
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public["1a"].id, aws_subnet.public["1b"].id]
  tags               = module.naming.mandatory_tags
}

# Target Group
resource "aws_lb_target_group" "web" {
  name        = module.naming.name.target_group_alb
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  tags        = module.naming.mandatory_tags

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.main.arn
  tags              = module.naming.mandatory_tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

### CloudWatch Monitoring

```hcl
module "naming" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "api"
  criticality = "high"
  backup      = "none"
  layer       = "application"
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = module.naming.name.dashboard

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "ap-southeast-2"
          title  = "ECS CPU Utilization"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${module.naming.name.alarm}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  tags                = module.naming.mandatory_tags
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "daily" {
  name                = module.naming.name.eventbridge_rule
  description         = "Daily scheduled task"
  schedule_expression = "cron(0 2 * * ? *)"
  tags                = module.naming.mandatory_tags
}
```

---

## Multi-Application Example

Managing multiple applications in the same codebase:

```hcl
# API Application
module "naming_api" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "api"
  criticality = "critical"
  backup      = "tier-1"
  layer       = "application"
}

# Worker Application
module "naming_worker" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "worker"
  criticality = "high"
  backup      = "none"
  layer       = "application"
}

# Analytics Application
module "naming_analytics" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "analytics"
  criticality = "medium"
  backup      = "tier-2"
  layer       = "application"
}

# API Resources
resource "aws_ecs_cluster" "api" {
  name = module.naming_api.name.ecs_cluster
  tags = module.naming_api.mandatory_tags
}

# Worker Resources
resource "aws_lambda_function" "worker" {
  function_name = module.naming_worker.name.lambda
  tags          = module.naming_worker.mandatory_tags
}

# Analytics Resources
resource "aws_rds_cluster" "analytics" {
  cluster_identifier = module.naming_analytics.name.aurora_cluster
  tags               = module.naming_analytics.mandatory_tags
}
```

---

## Additional Tags Example

Adding custom tags beyond the 7 mandatory tags:

```hcl
module "naming" {
  source      = "./labelling"
  environment = "prd"
  repository  = "infrastructure-repo"
  application = "api"
  criticality = "critical"
  backup      = "tier-1"
  layer       = "application"

  additional_tags = {
    Team        = "Platform Engineering"
    CostCenter  = "CC-1234"
    Compliance  = "PCI-DSS"
    DataClass   = "Confidential"
  }
}

# All resources will now have 11 tags:
# - Application, Environment, Criticality, Backup, ManagedBy, Layer, Repository (mandatory)
# - Team, CostCenter, Compliance, DataClass (additional)

resource "aws_s3_bucket" "data" {
  bucket = module.naming.name.s3_bucket
  tags   = module.naming.mandatory_tags
  # Tags include all 10 tags automatically
}
```

---

## Best Practices

### 1. Use Provider Default Tags

Reduce repetition by using provider `default_tags`:

```hcl
provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = module.naming.default_tags
  }
}

# Now most resources don't need explicit tags
resource "aws_s3_bucket" "data" {
  bucket = module.naming.name.s3_bucket
  # Tags automatically applied
}
```

### 2. Security Group Naming

Use `name_prefix` with security groups to allow recreates:

```hcl
resource "aws_security_group" "app" {
  name_prefix = "${module.naming.prefix}-app-"
  vpc_id      = aws_vpc.main.id
  tags        = module.naming.tags_with_name.security_group

  lifecycle {
    create_before_destroy = true
  }
}
```

### 3. S3 Bucket Naming

S3 buckets must be globally unique. Consider adding account ID or region:

```hcl
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${module.naming.name.s3_bucket_artifacts}-${data.aws_caller_identity.current.account_id}"
  tags   = module.naming.mandatory_tags
}
```

### 4. IAM Role Naming

Use descriptive role names with the application context:

```hcl
# Good
module "naming" {
  source      = "./labelling"
  repository  = "infrastructure-repo"
  application = "api-ecs-task"
  # Results in: whub-prd-api-ecs-task-role
}

# Avoid
module "naming" {
  source      = "./labelling"
  repository  = "infrastructure-repo"
  application = "role"  # Too generic
}
```

---

## Reference: All Available Names

See `outputs.tf` for the complete list of 95+ predefined resource names covering all AWS services used in WineHub infrastructure, including:

- **Compute** (EC2, Lambda, ECS)
- **Networking** (VPC, Security Groups, ALB, NLB)
- **Database & Caching** (RDS, Aurora, ElastiCache, DMS)
- **Storage** (S3, DynamoDB, ECR)
- **Messaging** (SQS)
- **IAM & Security** (Roles, Policies, Secrets Manager, SSM)
- **DNS** (Route53)
- **API Gateway** (HTTP APIs)
- **Content Delivery & Security** (CloudFront, WAF)
- **Observability** (CloudWatch, EventBridge, OAM, Prometheus)
- **Auto Scaling** (Application Auto Scaling)
