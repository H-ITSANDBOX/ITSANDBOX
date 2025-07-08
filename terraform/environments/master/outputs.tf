# Outputs for ITSANDBOX Master Account

output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = aws_organizations_organization.itsandbox.id
}

output "organization_arn" {
  description = "The ARN of the AWS Organization"
  value       = aws_organizations_organization.itsandbox.arn
}

output "organization_root_id" {
  description = "The root ID of the AWS Organization"
  value       = aws_organizations_organization.itsandbox.roots[0].id
}

output "security_ou_id" {
  description = "The ID of the Security OU"
  value       = aws_organizations_organizational_unit.security.id
}

output "production_ou_id" {
  description = "The ID of the Production OU"
  value       = aws_organizations_organizational_unit.production.id
}

output "projects_ou_id" {
  description = "The ID of the Projects OU"
  value       = aws_organizations_organizational_unit.projects.id
}

output "cost_control_policy_id" {
  description = "The ID of the cost control policy"
  value       = aws_organizations_policy.cost_control.id
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_bucket.bucket
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.organization_trail.arn
}

output "cost_monitor_lambda_arn" {
  description = "ARN of the cost monitoring Lambda function"
  value       = aws_lambda_function.cost_monitor.arn
}

output "cost_alerts_topic_arn" {
  description = "ARN of the cost alerts SNS topic"
  value       = aws_sns_topic.cost_alerts.arn
}

output "budget_name" {
  description = "Name of the organization budget"
  value       = aws_budgets_budget.organization_budget.name
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cost_dashboard.dashboard_name}"
}