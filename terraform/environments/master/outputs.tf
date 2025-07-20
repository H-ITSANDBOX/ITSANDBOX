# Outputs for ITSANDBOX Master Account

# Organization outputs - temporarily disabled
# output "organization_id" {
#   description = "The ID of the AWS Organization"
#   value       = aws_organizations_organization.itsandbox.id
# }
#
# output "organization_arn" {
#   description = "The ARN of the AWS Organization"
#   value       = aws_organizations_organization.itsandbox.arn
# }
#
# output "organization_root_id" {
#   description = "The root ID of the AWS Organization"
#   value       = aws_organizations_organization.itsandbox.roots[0].id
# }
#
# output "security_ou_id" {
#   description = "The ID of the Security OU"
#   value       = aws_organizations_organizational_unit.security.id
# }
#
# output "production_ou_id" {
#   description = "The ID of the Production OU"
#   value       = aws_organizations_organizational_unit.production.id
# }
#
# output "projects_ou_id" {
#   description = "The ID of the Projects OU"
#   value       = aws_organizations_organizational_unit.projects.id
# }
#
# output "cost_control_policy_id" {
#   description = "The ID of the cost control policy"
#   value       = aws_organizations_policy.cost_control.id
# }

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

# ====================
# Security Services Outputs
# ====================

output "security_services" {
  description = "Security services configuration and URLs"
  value = {
    config = {
      configuration_recorder = module.security_services.config_configuration_recorder_name
      delivery_channel      = module.security_services.config_delivery_channel_name
      s3_bucket            = module.security_services.config_s3_bucket_name
      iam_role_arn         = module.security_services.config_iam_role_arn
      console_url          = module.security_services.config_console_url
    }
    guardduty = {
      detector_id         = module.security_services.guardduty_detector_id
      detector_arn        = module.security_services.guardduty_detector_arn
      eventbridge_rule    = module.security_services.guardduty_eventbridge_rule_name
      console_url         = module.security_services.guardduty_console_url
    }
    security_hub = {
      account_id          = module.security_services.security_hub_account_id
      standards           = module.security_services.security_hub_standards_subscriptions
      insight_arn         = module.security_services.security_hub_insight_arn
      console_url         = module.security_services.security_hub_console_url
    }
    monitoring = {
      alerts_topic_arn    = module.security_services.security_alerts_topic_arn
      alerts_topic_name   = module.security_services.security_alerts_topic_name
      dashboard_url       = module.security_services.security_dashboard_url
      dashboard_name      = module.security_services.security_dashboard_name
    }
  }
}

output "security_console_urls" {
  description = "Quick access URLs for security consoles"
  value = {
    config       = module.security_services.config_console_url
    guardduty    = module.security_services.guardduty_console_url
    security_hub = module.security_services.security_hub_console_url
    dashboard    = module.security_services.security_dashboard_url
  }
}