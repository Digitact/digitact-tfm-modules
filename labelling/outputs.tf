# =============================================================================
# WineHub Naming & Tagging Module - Outputs
# =============================================================================
#
# Provides standardized names for AWS resources using simplified naming:
#   - Pattern: {product}-{env}-{app}
#   - Example: whub-np-observability
#   - Resource type identified by Terraform resource type and tags, not name suffix
#
# Usage:
#   module.naming.name -> "whub-np-api" (use for all single resources)
#   module.naming.name_with_suffix.alb -> "whub-np-api-alb" (optional backwards compatibility)
#
# =============================================================================

output "prefix" {
  description = "Base resource name prefix ({product}-{env}-{app})"
  value       = local.prefix
}

output "name" {
  description = "Resource name without type suffix - use this for most resources. AWS tags identify the resource type."
  value       = local.prefix
}

output "name_with_suffix" {
  description = <<-EOD
    Optional: Resource names with type suffixes for backwards compatibility or disambiguation.
    Prefer using 'name' output directly - resource type is clear from Terraform resource type and tags.
  EOD
  value = {
    # =========================================================================
    # COMPUTE
    # =========================================================================
    ec2_instance = "${local.prefix}-ec2"

    lambda            = "${local.prefix}-lambda"
    lambda_role       = "${local.prefix}-lambda-role"
    lambda_layer      = "${local.prefix}-layer"
    lambda_permission = "${local.prefix}-lambda-permission"

    ecs_cluster             = "${local.prefix}-ecs"
    ecs_service             = "${local.prefix}-svc"
    ecs_task_definition     = "${local.prefix}-task"
    ecs_task_execution_role = "${local.prefix}-ecs-exec-role"
    ecs_task_role           = "${local.prefix}-ecs-task-role"

    # =========================================================================
    # NETWORKING
    # =========================================================================
    vpc              = "${local.prefix}-vpc"
    internet_gateway = "${local.prefix}-igw"
    nat_gateway      = "${local.prefix}-nat"
    vpn_gateway      = "${local.prefix}-vgw"

    security_group = "${local.prefix}-sg"
    vpc_endpoint   = "${local.prefix}-vpce"
    vpc_peering    = "${local.prefix}-peer"
    eip            = "${local.prefix}-eip"

    # Load Balancers
    alb          = "${local.prefix}-alb"
    nlb          = "${local.prefix}-nlb"
    target_group = "${local.prefix}-tg"

    # =========================================================================
    # DATABASE & CACHING
    # =========================================================================
    rds_instance = "${local.prefix}-rds"
    rds_cluster  = "${local.prefix}-rds"

    aurora_cluster  = "${local.prefix}-aurora"
    aurora_instance = "${local.prefix}-aurora-inst"

    elasticache_cluster = "${local.prefix}-redis"
    elasticache_group   = "${local.prefix}-redis"

    # =========================================================================
    # STORAGE
    # =========================================================================
    s3_bucket = local.prefix  # No suffix - globally unique with account ID

    dynamodb_table = "${local.prefix}-table"
    ecr_repository = local.prefix

    # =========================================================================
    # MESSAGING
    # =========================================================================
    sqs_queue      = "${local.prefix}-queue"
    sqs_queue_dlq  = "${local.prefix}-dlq"
    sqs_queue_fifo = "${local.prefix}-queue.fifo"

    sns_topic = "${local.prefix}-topic"

    # =========================================================================
    # IAM & SECURITY
    # =========================================================================
    iam_role             = "${local.prefix}-role"
    iam_policy           = "${local.prefix}-policy"
    iam_instance_profile = "${local.prefix}-profile"
    iam_user             = "${local.prefix}-user"

    secret                = "${local.prefix}-secret"
    secret_db_credentials = "${local.prefix}/db/credentials"
    secret_api_key        = "${local.prefix}/api/key"

    ssm_parameter = "/${local.prefix}"
    ssm_path      = "/${local.prefix}"

    acm_certificate = "${local.prefix}-cert"

    # =========================================================================
    # DNS
    # =========================================================================
    route53_zone   = "${var.application}.${var.environment}.example.com"
    route53_record = local.prefix

    # =========================================================================
    # API GATEWAY
    # =========================================================================
    api_gateway       = "${local.prefix}-api"
    api_gateway_stage = var.environment

    # =========================================================================
    # WAF & CDN
    # =========================================================================
    cloudfront_distribution = "${local.prefix}-cdn"
    waf_web_acl             = "${local.prefix}-waf"
    waf_ip_set              = "${local.prefix}-ipset"

    # =========================================================================
    # OBSERVABILITY
    # =========================================================================
    log_group             = "/aws/${local.prefix}"
    log_group_lambda      = "/aws/lambda/${local.prefix}"
    log_group_ecs         = "/aws/ecs/${local.prefix}"
    log_group_rds         = "/aws/rds/${local.prefix}"
    log_group_application = "/application/${local.prefix}"

    alarm                = "${local.prefix}-alarm"
    dashboard            = "${local.prefix}-dashboard"
    eventbridge_rule     = "${local.prefix}-rule"
    prometheus_workspace = "${local.prefix}-amp"

    # =========================================================================
    # AUTO SCALING & SCHEDULING
    # =========================================================================
    autoscaling_target = "${local.prefix}-autoscaling"
    autoscaling_policy = "${local.prefix}-scaling-policy"

    scheduler      = "${local.prefix}-scheduler"
    scheduler_role = "${local.prefix}-scheduler-role"

    # =========================================================================
    # BACKUP
    # =========================================================================
    backup_plan  = "${local.prefix}-backup"
    backup_vault = "${local.prefix}-vault"
  }
}

output "name_tag" {
  description = "Map of resource types requiring Name tags (for resources identified primarily by tags, like subnets and security groups)"
  value = {
    # VPC Resources
    vpc              = "${local.prefix}-vpc"
    internet_gateway = "${local.prefix}-igw"
    nat_gateway      = "${local.prefix}-nat"
    vpn_gateway      = "${local.prefix}-vgw"

    # Subnets (keep AZ suffixes for disambiguation)
    subnet_public_1a  = "${local.prefix}-public-1a"
    subnet_public_1b  = "${local.prefix}-public-1b"
    subnet_public_1c  = "${local.prefix}-public-1c"
    subnet_private_1a = "${local.prefix}-private-1a"
    subnet_private_1b = "${local.prefix}-private-1b"
    subnet_private_1c = "${local.prefix}-private-1c"
    subnet_secure_1a  = "${local.prefix}-secure-1a"
    subnet_secure_1b  = "${local.prefix}-secure-1b"
    subnet_secure_1c  = "${local.prefix}-secure-1c"

    # Route Tables (keep type suffixes for disambiguation)
    route_table_public  = "${local.prefix}-rt-public"
    route_table_private = "${local.prefix}-rt-private"

    # Security Groups (keep service suffixes when multiple SGs exist)
    security_group              = "${local.prefix}-sg"
    security_group_alb          = "${local.prefix}-alb-sg"
    security_group_ecs          = "${local.prefix}-ecs-sg"
    security_group_rds          = "${local.prefix}-rds-sg"
    security_group_redis        = "${local.prefix}-redis-sg"
    security_group_lambda       = "${local.prefix}-lambda-sg"
    security_group_bastion      = "${local.prefix}-bastion-sg"
    security_group_vpc_endpoint = "${local.prefix}-vpce-sg"

    # EC2 Instances (Name tag is primary identifier)
    ec2_instance = local.prefix
    ec2_bastion  = "${local.prefix}-bastion"
    ec2_worker   = "${local.prefix}-worker"

    # EIPs
    eip     = "${local.prefix}-eip"
    eip_nat = "${local.prefix}-nat-eip"

    # VPC Endpoints
    vpc_endpoint_s3       = "${local.prefix}-s3-vpce"
    vpc_endpoint_dynamodb = "${local.prefix}-dynamodb-vpce"
    vpc_endpoint_ecr_api  = "${local.prefix}-ecr-api-vpce"
    vpc_endpoint_ecr_dkr  = "${local.prefix}-ecr-dkr-vpce"

    vpc_peering = "${local.prefix}-peer"
  }
}

output "mandatory_tags" {
  description = "All mandatory tags including Repository (for resource-level tags)"
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
    Repository  = var.repository
  }
}

output "tags_with_name" {
  description = "Helper: Returns mandatory tags merged with a Name tag for specific resource types (use with name_tag map keys)"
  value = { for k, v in {
    vpc              = merge(local.mandatory_tags, { Name = "${local.prefix}-vpc" })
    internet_gateway = merge(local.mandatory_tags, { Name = "${local.prefix}-igw" })
    nat_gateway      = merge(local.mandatory_tags, { Name = "${local.prefix}-nat" })
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

    ec2_instance = merge(local.mandatory_tags, { Name = local.prefix })
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
