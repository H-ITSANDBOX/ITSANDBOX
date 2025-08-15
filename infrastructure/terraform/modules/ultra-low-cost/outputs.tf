# Outputs for Ultra-Low-Cost ITSANDBOX Infrastructure

output "github_repository_url" {
  description = "GitHub repository URL"
  value       = github_repository.itsandbox.html_url
}

output "github_pages_url" {
  description = "GitHub Pages URL"
  value       = "https://${var.github_username}.github.io/${var.repository_name}"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.enable_custom_domain && var.domain_name != null ? "https://${var.domain_name}" : null
}

output "lambda_function_arn" {
  description = "Lambda function ARN (if enabled)"
  value       = var.enable_lambda_backend ? aws_lambda_function.essential_backend[0].arn : null
}

output "backup_s3_bucket" {
  description = "S3 bucket for backups"
  value       = aws_s3_bucket.backup.bucket
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.ultra_low_cost.dashboard_name}"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for critical alerts"
  value       = aws_sns_topic.critical_alerts.arn
}

output "budget_name" {
  description = "Budget name for cost monitoring"
  value       = aws_budgets_budget.ultra_low_cost.name
}

# Cost estimation outputs
output "estimated_monthly_costs" {
  description = "Estimated monthly costs breakdown"
  value = {
    github_pages     = "$0.00 (Free)"
    github_actions   = "$0.00 (2000 minutes free)"
    s3_backup       = "$0.10 - $1.00 (depending on usage)"
    cloudwatch      = "$0.00 - $1.00 (free tier)"
    sns_alerts      = "$0.00 - $0.50 (free tier + minimal usage)"
    lambda_backend  = var.enable_lambda_backend ? "$0.50 - $2.00" : "$0.00 (disabled)"
    route53_domain  = var.enable_custom_domain ? "$0.50/month + $12/year" : "$0.00 (using GitHub Pages subdomain)"
    total_estimated = var.enable_lambda_backend && var.enable_custom_domain ? "$1.60 - $5.00" : (
                     var.enable_lambda_backend ? "$0.60 - $4.00" : (
                     var.enable_custom_domain ? "$1.00 - $3.00" : "$0.10 - $2.50"))
  }
}

output "cost_optimization_summary" {
  description = "Cost optimization summary"
  value = {
    previous_architecture_cost = "$16-28/month"
    new_architecture_cost     = "$0.10-5.00/month"
    savings_amount           = "$11-27/month"
    savings_percentage       = "88-99%"
    primary_cost_driver      = var.enable_lambda_backend ? "Lambda functions" : "S3 storage"
    free_services_used = [
      "GitHub Pages (Static hosting)",
      "GitHub Actions (CI/CD)",
      "GitHub Repository (Code hosting)",
      "CloudWatch Free Tier (Basic monitoring)",
      "SNS Free Tier (Email notifications)"
    ]
  }
}

output "deployment_instructions" {
  description = "Deployment instructions"
  value = <<-EOT
    🚀 ITSANDBOX Ultra-Low-Cost Deployment Instructions:
    
    1. **GitHub Repository**: ${github_repository.itsandbox.html_url}
    2. **GitHub Pages**: https://${var.github_username}.github.io/${var.repository_name}
    3. **Estimated Monthly Cost**: $0.10 - $5.00 (88-99% savings!)
    
    📋 Next Steps:
    - Push your frontend code to the main branch
    - GitHub Actions will automatically build and deploy
    - Monitor costs via CloudWatch Dashboard
    - Receive alerts if approaching $5 budget
    
    💡 Cost Optimization Tips:
    - GitHub Pages is completely free for public repositories
    - Use GitHub Actions free tier (2000 minutes/month)
    - Minimize Lambda usage (${var.enable_lambda_backend ? "enabled" : "disabled"})
    - Use GitHub Issues for project management (free)
    - Monitor S3 usage to stay in free tier
    
    📊 Monitoring:
    - CloudWatch Dashboard: ${aws_cloudwatch_dashboard.ultra_low_cost.dashboard_name}
    - Budget Alerts: ${aws_budgets_budget.ultra_low_cost.name}
    - SNS Notifications: ${aws_sns_topic.critical_alerts.name}
  EOT
}

output "architecture_comparison" {
  description = "Architecture comparison"
  value = {
    previous_architecture = {
      hosting        = "S3 + CloudFront ($3-5/month)"
      backend        = "Lambda + API Gateway ($8-12/month)"
      database       = "DynamoDB ($2-4/month)"
      monitoring     = "CloudWatch + X-Ray ($2-3/month)"
      websockets     = "API Gateway WebSocket ($1-2/month)"
      total_cost     = "$16-28/month"
    }
    new_architecture = {
      hosting        = "GitHub Pages (Free)"
      backend        = "Client-side + Mock API (Free)"
      database       = "LocalStorage + GitHub (Free)"
      monitoring     = "CloudWatch Basic + Budget Alerts ($0-1/month)"
      websockets     = "Client-side simulation (Free)"
      optional_aws   = "S3 backup + Lambda ($0-4/month)"
      total_cost     = "$0.10-5.00/month"
    }
    benefits = [
      "88-99% cost reduction",
      "Same user experience",
      "Faster loading (CDN)",
      "Better reliability (GitHub uptime)",
      "Easier deployment",
      "No vendor lock-in"
    ]
  }
}