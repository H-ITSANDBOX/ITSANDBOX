# ITSANDBOX Cost Management Module Outputs

output "budget_alerts_sns_topic_arn" {
  description = "ARN of the SNS topic for budget alerts"
  value       = aws_sns_topic.budget_alerts.arn
}

output "critical_alerts_sns_topic_arn" {
  description = "ARN of the SNS topic for critical budget alerts"
  value       = aws_sns_topic.critical_alerts.arn
}

output "cost_optimizer_lambda_arn" {
  description = "ARN of the cost optimizer Lambda function"
  value       = aws_lambda_function.cost_optimizer.arn
}

output "cost_management_dashboard_url" {
  description = "URL of the CloudWatch cost management dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cost_management.dashboard_name}"
}

output "organization_budget_arn" {
  description = "ARN of the organization-wide budget"
  value       = aws_budgets_budget.itsandbox_organization_budget.arn
}

output "account_budget_arns" {
  description = "ARNs of account-specific budgets"
  value       = { for k, v in aws_budgets_budget.account_budgets : k => v.arn }
}

output "cost_anomaly_detector_arn" {
  description = "ARN of the cost anomaly detector"
  value       = aws_ce_anomaly_detector.itsandbox_cost_anomaly.arn
}

output "cost_category_arn" {
  description = "ARN of the ITSANDBOX projects cost category"
  value       = aws_ce_cost_category.itsandbox_projects.arn
}

output "daily_cost_analysis_rule_arn" {
  description = "ARN of the daily cost analysis EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily_cost_analysis.arn
}

output "cost_optimization_summary" {
  description = "Summary of cost optimization configuration"
  value = {
    organization_budget_limit = var.organization_budget_limit
    total_account_budgets     = length(var.account_budgets)
    notification_emails       = length(var.admin_email_addresses)
    cost_anomaly_threshold    = var.cost_anomaly_threshold
    auto_optimization_enabled = var.enable_cost_optimization
  }
}