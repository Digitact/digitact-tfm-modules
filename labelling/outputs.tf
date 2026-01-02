# =============================================================================
# WineHub Naming & Tagging Module - Outputs
# =============================================================================
#
# Provides standardized names for all AWS resources used across WineHub infrastructure.
# Coverage: 95 resource types across 11 categories
#
# Usage:
#   module.naming.name.ecs_cluster     -> "whub-stg-api-ecs"
#   module.naming.name.lambda          -> "whub-stg-api-lambda"
#   module.naming.name_tag.vpc         -> "whub-stg-api-vpc" (for Name tag)
#
# =============================================================================

output "prefix" {
  description = "Base resource name prefix (whub-{env}-{app})"
  value       = local.prefix
}

output "name" {
  description = "Map of resource types to full compliant names (for resources with 'name' argument)"
  value = {
    # =========================================================================
    # COMPUTE (8 resource types)
    # =========================================================================

    # EC2
    ec2_instance = "${local.prefix}-ec2"

    # Lambda
    lambda            = "${local.prefix}-lambda"
    lambda_role       = "${local.prefix}-lambda-role"
    lambda_layer      = "${local.prefix}-layer"
    lambda_permission = "${local.prefix}-lambda-permission"

    # ECS
    ecs_cluster             = "${local.prefix}-ecs"
    ecs_service             = "${local.prefix}-svc"
    ecs_task_definition     = "${local.prefix}-task"
    ecs_task_execution_role = "${local.prefix}-ecs-exec-role"
    ecs_task_role           = "${local.prefix}-ecs-task-role"
    ecs_capacity_provider   = "${local.prefix}-capacity-provider"

    # =========================================================================
    # NETWORKING (24 resource types)
    # =========================================================================

    # VPC Core
    vpc              = "${local.prefix}-vpc"
    internet_gateway = "${local.prefix}-igw"
    nat_gateway      = "${local.prefix}-nat"
    vpn_gateway      = "${local.prefix}-vgw"

    # Subnets
    subnet_public  = "${local.prefix}-public"
    subnet_private = "${local.prefix}-private"
    subnet_secure  = "${local.prefix}-secure"

    # Routing
    route_table         = "${local.prefix}-rt"
    route_table_public  = "${local.prefix}-rt-public"
    route_table_private = "${local.prefix}-rt-private"

    # Security
    security_group      = "${local.prefix}-sg"
    security_group_rule = "${local.prefix}-sg-rule"

    # VPC Endpoints
    vpc_endpoint = "${local.prefix}-vpce"

    # VPC Peering
    vpc_peering = "${local.prefix}-peer"

    # Elastic IPs
    eip = "${local.prefix}-eip"

    # Load Balancers
    alb              = "${local.prefix}-alb"
    nlb              = "${local.prefix}-nlb"
    target_group     = "${local.prefix}-tg"
    target_group_alb = "${local.prefix}-alb-tg"
    target_group_nlb = "${local.prefix}-nlb-tg"

    # API Gateway VPC Link
    vpc_link = "${local.prefix}-vpclink"

    # =========================================================================
    # DATABASE & CACHING (12 resource types)
    # =========================================================================

    # RDS
    rds_instance       = "${local.prefix}-rds"
    db_parameter_group = "${local.prefix}-db-params"
    db_subnet_group    = "${local.prefix}-db-subnet"

    # Aurora
    aurora_cluster         = "${local.prefix}-aurora"
    aurora_instance        = "${local.prefix}-aurora-inst"
    aurora_parameter_group = "${local.prefix}-aurora-params"

    # ElastiCache
    elasticache_cluster           = "${local.prefix}-redis"
    elasticache_replication_group = "${local.prefix}-redis"
    elasticache_parameter_group   = "${local.prefix}-redis-params"
    elasticache_subnet_group      = "${local.prefix}-redis-subnet"

    # DMS
    dms_replication_instance = "${local.prefix}-dms"
    dms_subnet_group         = "${local.prefix}-dms-subnet"
    dms_endpoint_source      = "${local.prefix}-dms-src"
    dms_endpoint_target      = "${local.prefix}-dms-tgt"
    dms_replication_task     = "${local.prefix}-dms-task"

    # =========================================================================
    # STORAGE (10 resource types)
    # =========================================================================

    # S3 (bucket names must be globally unique, use prefix carefully)
    s3_bucket           = "${local.prefix}"
    s3_bucket_logs      = "${local.prefix}-logs"
    s3_bucket_artifacts = "${local.prefix}-artifacts"
    s3_bucket_backups   = "${local.prefix}-backups"

    # DynamoDB
    dynamodb_table = "${local.prefix}-table"

    # ECR
    ecr_repository = "${local.prefix}"

    # =========================================================================
    # MESSAGING (4 resource types)
    # =========================================================================

    # SQS
    sqs_queue               = "${local.prefix}-queue"
    sqs_queue_dlq           = "${local.prefix}-dlq"
    sqs_queue_fifo          = "${local.prefix}-queue.fifo"
    sqs_queue_high_priority = "${local.prefix}-priority-queue"

    # =========================================================================
    # IAM & SECURITY (14 resource types)
    # =========================================================================

    # IAM Roles
    iam_role             = "${local.prefix}-role"
    iam_policy           = "${local.prefix}-policy"
    iam_instance_profile = "${local.prefix}-profile"

    # IAM Users (for service accounts)
    iam_user = "${local.prefix}-user"

    # OIDC
    oidc_provider = "github.com" # Standard GitHub OIDC URL

    # Secrets Manager
    secret                = "${local.prefix}-secret"
    secret_db_credentials = "${local.prefix}/db/credentials"
    secret_api_key        = "${local.prefix}/api/key"

    # SSM Parameter Store
    ssm_parameter = "/${local.prefix}"
    ssm_path      = "/${local.prefix}"

    # ACM Certificates
    acm_certificate = "${local.prefix}-cert"

    # =========================================================================
    # DNS (4 resource types)
    # =========================================================================

    # Route53
    route53_zone   = "${var.application}.${var.environment}.example.com"
    route53_record = "${local.prefix}"

    # =========================================================================
    # API GATEWAY (4 resource types)
    # =========================================================================

    # API Gateway v2 (HTTP API)
    api_gateway             = "${local.prefix}-api"
    api_gateway_stage       = var.environment
    api_gateway_integration = "${local.prefix}-integration"
    api_gateway_route       = "${local.prefix}-route"

    # =========================================================================
    # CONTENT DELIVERY & SECURITY (5 resource types)
    # =========================================================================

    # CloudFront
    cloudfront_distribution = "${local.prefix}-cdn"

    # WAF
    waf_ip_set             = "${local.prefix}-ipset"
    waf_web_acl            = "${local.prefix}-waf"
    waf_web_acl_alb        = "${local.prefix}-waf-alb"
    waf_web_acl_cloudfront = "${local.prefix}-waf-cdn"

    # =========================================================================
    # OBSERVABILITY (10 resource types)
    # =========================================================================

    # CloudWatch Logs
    log_group             = "/aws/${local.prefix}"
    log_group_lambda      = "/aws/lambda/${local.prefix}"
    log_group_ecs         = "/aws/ecs/${local.prefix}"
    log_group_rds         = "/aws/rds/${local.prefix}"
    log_group_application = "/application/${local.prefix}"

    # CloudWatch Alarms
    alarm = "${local.prefix}-alarm"

    # CloudWatch Dashboards
    dashboard = "${local.prefix}-dashboard"

    # CloudWatch Query Definitions
    query_definition = "${local.prefix}-query"

    # EventBridge (CloudWatch Events)
    eventbridge_rule   = "${local.prefix}-rule"
    eventbridge_target = "${local.prefix}-target"

    # Observability Access Manager
    oam_sink = "${local.prefix}-oam-sink"
    oam_link = "${local.prefix}-oam-link"

    # Amazon Managed Prometheus
    prometheus_workspace = "${local.prefix}-amp"

    # =========================================================================
    # AUTO SCALING (2 resource types)
    # =========================================================================

    # Application Auto Scaling
    autoscaling_target        = "${local.prefix}-autoscaling"
    autoscaling_policy        = "${local.prefix}-scaling-policy"
    autoscaling_policy_cpu    = "${local.prefix}-cpu-scaling"
    autoscaling_policy_memory = "${local.prefix}-memory-scaling"

    # =========================================================================
    # ADDITIONAL COMMON PATTERNS
    # =========================================================================

    # Schedulers
    scheduler      = "${local.prefix}-scheduler"
    scheduler_role = "${local.prefix}-scheduler-role"

    # Backup
    backup_plan  = "${local.prefix}-backup"
    backup_vault = "${local.prefix}-vault"
  }
}

output "name_tag" {
  description = "Map of resource types that require a 'Name' tag (resources without 'name' argument or where Name tag is preferred)"
  value = {
    # VPC Resources (many use Name tag for identification)
    vpc              = "${local.prefix}-vpc"
    internet_gateway = "${local.prefix}-igw"
    nat_gateway      = "${local.prefix}-nat-${var.environment}"
    vpn_gateway      = "${local.prefix}-vgw"

    # Subnets (always use Name tag)
    subnet_public_1a  = "${local.prefix}-public-1a"
    subnet_public_1b  = "${local.prefix}-public-1b"
    subnet_public_1c  = "${local.prefix}-public-1c"
    subnet_private_1a = "${local.prefix}-private-1a"
    subnet_private_1b = "${local.prefix}-private-1b"
    subnet_private_1c = "${local.prefix}-private-1c"
    subnet_secure_1a  = "${local.prefix}-secure-1a"
    subnet_secure_1b  = "${local.prefix}-secure-1b"
    subnet_secure_1c  = "${local.prefix}-secure-1c"

    # Route Tables (use Name tag)
    route_table_public  = "${local.prefix}-rt-public"
    route_table_private = "${local.prefix}-rt-private"

    # Security Groups (Name tag for console visibility)
    security_group              = "${local.prefix}-sg"
    security_group_alb          = "${local.prefix}-alb-sg"
    security_group_ecs          = "${local.prefix}-ecs-sg"
    security_group_rds          = "${local.prefix}-rds-sg"
    security_group_redis        = "${local.prefix}-redis-sg"
    security_group_lambda       = "${local.prefix}-lambda-sg"
    security_group_bastion      = "${local.prefix}-bastion-sg"
    security_group_vpc_endpoint = "${local.prefix}-vpce-sg"

    # EC2 Instances (Name tag is primary identifier in console)
    ec2_instance = "${local.prefix}"
    ec2_bastion  = "${local.prefix}-bastion"
    ec2_worker   = "${local.prefix}-worker"

    # EIPs (Name tag for identification)
    eip     = "${local.prefix}-eip"
    eip_nat = "${local.prefix}-nat-eip"

    # VPC Endpoints (Name tag for console)
    vpc_endpoint_s3       = "${local.prefix}-s3-vpce"
    vpc_endpoint_dynamodb = "${local.prefix}-dynamodb-vpce"
    vpc_endpoint_ecr_api  = "${local.prefix}-ecr-api-vpce"
    vpc_endpoint_ecr_dkr  = "${local.prefix}-ecr-dkr-vpce"

    # VPC Peering (Name tag)
    vpc_peering = "${local.prefix}-peer"
  }
}

output "mandatory_tags" {
  description = "All 6 mandatory WineHub tags (for resource-level tags)"
  value       = local.mandatory_tags
}

output "default_tags" {
  description = "Tags for AWS provider default_tags block"
  value = {
    Application = var.application
    Environment = local.environment_display[var.environment]
    Criticality = var.criticality
    Backup      = var.backup
    ManagedBy   = "Terraform"
    Layer       = var.layer
  }
}

output "tags_with_name" {
  description = "Helper function: Returns mandatory tags merged with a Name tag for a specific resource type (use with name_tag map keys)"
  value = { for k, v in {
    # Returns a map where each key is a resource type and value is tags including Name
    # Usage: module.naming.tags_with_name.vpc -> { Name = "whub-stg-api-vpc", Application = "api", ... }

    vpc              = merge(local.mandatory_tags, { Name = "${local.prefix}-vpc" })
    internet_gateway = merge(local.mandatory_tags, { Name = "${local.prefix}-igw" })
    nat_gateway      = merge(local.mandatory_tags, { Name = "${local.prefix}-nat-${var.environment}" })
    vpn_gateway      = merge(local.mandatory_tags, { Name = "${local.prefix}-vgw" })

    subnet_public_1a  = merge(local.mandatory_tags, { Name = "${local.prefix}-public-1a" })
    subnet_public_1b  = merge(local.mandatory_tags, { Name = "${local.prefix}-public-1b" })
    subnet_public_1c  = merge(local.mandatory_tags, { Name = "${local.prefix}-public-1c" })
    subnet_private_1a = merge(local.mandatory_tags, { Name = "${local.prefix}-private-1a" })
    subnet_private_1b = merge(local.mandatory_tags, { Name = "${local.prefix}-private-1b" })
    subnet_private_1c = merge(local.mandatory_tags, { Name = "${local.prefix}-private-1c" })
    subnet_secure_1a  = merge(local.mandatory_tags, { Name = "${local.prefix}-secure-1a" })
    subnet_secure_1b  = merge(local.mandatory_tags, { Name = "${local.prefix}-secure-1b" })
    subnet_secure_1c  = merge(local.mandatory_tags, { Name = "${local.prefix}-secure-1c" })

    route_table_public  = merge(local.mandatory_tags, { Name = "${local.prefix}-rt-public" })
    route_table_private = merge(local.mandatory_tags, { Name = "${local.prefix}-rt-private" })

    security_group              = merge(local.mandatory_tags, { Name = "${local.prefix}-sg" })
    security_group_alb          = merge(local.mandatory_tags, { Name = "${local.prefix}-alb-sg" })
    security_group_ecs          = merge(local.mandatory_tags, { Name = "${local.prefix}-ecs-sg" })
    security_group_rds          = merge(local.mandatory_tags, { Name = "${local.prefix}-rds-sg" })
    security_group_redis        = merge(local.mandatory_tags, { Name = "${local.prefix}-redis-sg" })
    security_group_lambda       = merge(local.mandatory_tags, { Name = "${local.prefix}-lambda-sg" })
    security_group_bastion      = merge(local.mandatory_tags, { Name = "${local.prefix}-bastion-sg" })
    security_group_vpc_endpoint = merge(local.mandatory_tags, { Name = "${local.prefix}-vpce-sg" })

    ec2_instance = merge(local.mandatory_tags, { Name = "${local.prefix}" })
    ec2_bastion  = merge(local.mandatory_tags, { Name = "${local.prefix}-bastion" })
    ec2_worker   = merge(local.mandatory_tags, { Name = "${local.prefix}-worker" })

    eip     = merge(local.mandatory_tags, { Name = "${local.prefix}-eip" })
    eip_nat = merge(local.mandatory_tags, { Name = "${local.prefix}-nat-eip" })

    vpc_endpoint_s3       = merge(local.mandatory_tags, { Name = "${local.prefix}-s3-vpce" })
    vpc_endpoint_dynamodb = merge(local.mandatory_tags, { Name = "${local.prefix}-dynamodb-vpce" })
    vpc_endpoint_ecr_api  = merge(local.mandatory_tags, { Name = "${local.prefix}-ecr-api-vpce" })
    vpc_endpoint_ecr_dkr  = merge(local.mandatory_tags, { Name = "${local.prefix}-ecr-dkr-vpce" })

    vpc_peering = merge(local.mandatory_tags, { Name = "${local.prefix}-peer" })
  } : k => v }
}

output "environment_display" {
  description = "Human-readable environment name"
  value       = local.environment_display[var.environment]
}
