# ITSANDBOX Ultra-Low-Cost Infrastructure Outputs

# ====================
# Website URLs and Endpoints
# ====================

output "website_url" {
  description = "The URL of the website"
  value       = var.enable_custom_domain ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "s3_website_url" {
  description = "S3 website endpoint URL"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

# ====================
# AWS Resource Information
# ====================

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

# ====================
# DNS and SSL Information
# ====================

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = var.enable_custom_domain ? aws_route53_zone.main[0].zone_id : null
}

output "route53_name_servers" {
  description = "Route 53 name servers (configure these with your domain registrar)"
  value       = var.enable_custom_domain ? aws_route53_zone.main[0].name_servers : null
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = var.enable_custom_domain ? aws_acm_certificate.website[0].arn : null
}

output "ssl_certificate_status" {
  description = "Status of SSL certificate validation"
  value       = var.enable_custom_domain ? aws_acm_certificate.website[0].status : "Not applicable (custom domain disabled)"
}

# ====================
# Cost and Monitoring
# ====================

output "budget_name" {
  description = "Name of the cost budget"
  value       = aws_budgets_budget.monthly_cost.name
}

output "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  value       = "$${var.organization_budget_limit}"
}

# ====================
# Deployment Information
# ====================

output "deployment_region" {
  description = "AWS region where resources are deployed"
  value       = "us-east-1"
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "terraform_workspace" {
  description = "Terraform workspace"
  value       = terraform.workspace
}

# ====================
# Next Steps Instructions
# ====================

output "next_steps" {
  description = "Instructions for completing the deployment"
  value = var.enable_custom_domain ? format(<<-EOT
🎉 ITSANDBOX Ultra-Low-Cost Deployment Complete!

✅ Website URL: https://%s
✅ CloudFront URL: https://%s
✅ Monthly Budget: $%s

📋 IMPORTANT: Configure DNS
To activate your custom domain, configure these name servers with your domain registrar:
%s

📊 Cost Breakdown (Estimated Monthly):
• S3 Storage (1GB):        $0.02
• CloudFront (1TB):        $8.50
• Route 53 Hosted Zone:    $0.50
• Route 53 Queries (1M):   $0.40
• ACM Certificate:         FREE
• Budget Alerts:           FREE
-----------------------------------
• Total Est:               $9.42/month

⚠️  Note: Costs may vary based on usage. Monitor via AWS Cost Explorer.

🔗 Access your website at: https://%s
EOT
    , var.domain_name, aws_cloudfront_distribution.website.domain_name, var.organization_budget_limit, join("\n    ", var.enable_custom_domain ? aws_route53_zone.main[0].name_servers : []), var.domain_name) : format(<<-EOT
🎉 ITSANDBOX Ultra-Low-Cost Deployment Complete!

✅ Website URL: https://%s
✅ Monthly Budget: $%s

📊 Cost Breakdown (Estimated Monthly):
• S3 Storage (1GB):        $0.02
• CloudFront (1TB):        $8.50
• Budget Alerts:           FREE
-----------------------------------
• Total Est:               $8.52/month

💡 To add custom domain (hosei-itsandbox.com):
1. Set enable_custom_domain = true in terraform.tfvars
2. Run: terraform apply
3. Configure name servers with domain registrar

🔗 Access your website at: https://%s
EOT
  , aws_cloudfront_distribution.website.domain_name, var.organization_budget_limit, aws_cloudfront_distribution.website.domain_name)
}