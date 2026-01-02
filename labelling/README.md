<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to merge with mandatory tags | `map(string)` | `{}` | no |
| <a name="input_application"></a> [application](#input\_application) | Application name (e.g., zoho-crm, analytics, api)<br/><br/>IMPORTANT: Total prefix length (product-env-app) should not exceed 22 characters<br/>to ensure compatibility with ALB/NLB resources and allow 6-character developer suffixes.<br/><br/>Examples:<br/>- whub-prd-api (11 chars) ✓<br/>- whub-prd-analytics (17 chars) ✓<br/>- whub-nprd-zoho-crm (16 chars) ✓<br/>- whub-prd-customer-portal (23 chars) ✗ TOO LONG for ALB/NLB | `string` | n/a | yes |
| <a name="input_backup"></a> [backup](#input\_backup) | Backup tier for retention policy | `string` | `"none"` | no |
| <a name="input_criticality"></a> [criticality](#input\_criticality) | Business criticality level for support prioritization | `string` | `"medium"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code (prd, nprd, dev, stg) | `string` | n/a | yes |
| <a name="input_layer"></a> [layer](#input\_layer) | Architecture layer designation | `string` | `"application"` | no |
| <a name="input_product"></a> [product](#input\_product) | Product prefix for resource naming (e.g., 'whub' for WineHub, 'prkr' for PerkRunner) | `string` | `"whub"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_tags"></a> [default\_tags](#output\_default\_tags) | Tags for AWS provider default\_tags block |
| <a name="output_environment_display"></a> [environment\_display](#output\_environment\_display) | Human-readable environment name |
| <a name="output_mandatory_tags"></a> [mandatory\_tags](#output\_mandatory\_tags) | All 6 mandatory WineHub tags (for resource-level tags) |
| <a name="output_name"></a> [name](#output\_name) | Map of resource types to full compliant names (for resources with 'name' argument) |
| <a name="output_name_tag"></a> [name\_tag](#output\_name\_tag) | Map of resource types that require a 'Name' tag (resources without 'name' argument or where Name tag is preferred) |
| <a name="output_prefix"></a> [prefix](#output\_prefix) | Base resource name prefix (whub-{env}-{app}) |
| <a name="output_tags_with_name"></a> [tags\_with\_name](#output\_tags\_with\_name) | Helper function: Returns mandatory tags merged with a Name tag for a specific resource type (use with name\_tag map keys) |
<!-- END_TF_DOCS -->