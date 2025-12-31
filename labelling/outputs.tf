# =============================================================================
# WineHub Naming & Tagging Module - Outputs
# =============================================================================

output "prefix" {
  description = "Base resource name prefix (whub-{env}-{app})"
  value       = local.prefix
}

output "name" {
  description = "Map of resource types to full compliant names"
  value = {
    # Compute
    lambda      = "${local.prefix}-lambda"
    lambda_role = "${local.prefix}-lambda-role"
    ecs_cluster = "${local.prefix}-ecs"
    ecs_service = "${local.prefix}-svc"
    ecs_task    = "${local.prefix}-task"

    # Networking
    security_group = "${local.prefix}-sg"
    target_group   = "${local.prefix}-tg"
    alb            = "${local.prefix}-alb"

    # Storage & Logging
    log_group = "/aws/lambda/${local.prefix}"
    s3_bucket = "${local.prefix}"

    # Secrets & Config
    ssm_path = "/${local.prefix}"
    secret   = "${local.prefix}"

    # Scheduling
    scheduler      = "${local.prefix}-scheduler"
    scheduler_role = "${local.prefix}-scheduler-role"

    # IAM
    iam_role   = "${local.prefix}-role"
    iam_policy = "${local.prefix}-policy"
  }
}

output "mandatory_tags" {
  description = "All 6 mandatory WineHub tags (for resource-level tags)"
  value = merge({
    Application = var.application
    Environment = local.environment_display[var.environment]
    Criticality = var.criticality
    Backup      = var.backup
    ManagedBy   = "Terraform"
    Layer       = var.layer
  }, var.additional_tags)
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

output "environment_display" {
  description = "Human-readable environment name"
  value       = local.environment_display[var.environment]
}
