# ITSANDBOX Production Environment - Ultra-Low-Cost Architecture
# Estimated cost: $0-5/month (88-99% savings)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }

  # Optional: Configure remote state for team collaboration
  # backend "s3" {
  #   bucket = "itsandbox-terraform-state"
  #   key    = "production/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Configure providers
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project      = "ITSANDBOX"
      Environment  = "Production"
      ManagedBy    = "Terraform"
      CostTarget   = "Under5USD"
      Architecture = "Ultra-Low-Cost"
      University   = "Hosei"
      Department   = "IT Innovation Community"
    }
  }
}

provider "github" {
  owner = var.github_username
}

# Deploy the ultra-low-cost infrastructure
module "itsandbox_ultra_low_cost" {
  source = "../../modules/ultra-low-cost"

  # Basic configuration
  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  repository_name  = var.repository_name
  github_username  = var.github_username

  # Cost optimization settings
  budget_limit              = var.budget_limit
  budget_alert_threshold    = var.budget_alert_threshold
  
  # Optional features (adds cost)
  enable_custom_domain      = var.enable_custom_domain
  enable_lambda_backend     = var.enable_lambda_backend
  domain_name              = var.domain_name
  
  # Notifications
  admin_emails             = var.admin_emails
  notification_webhook_url = var.notification_webhook_url
  
  # AWS credentials for GitHub Actions
  aws_access_key_id        = var.aws_access_key_id
  aws_secret_access_key    = var.aws_secret_access_key
  
  # S3 lifecycle configuration
  s3_lifecycle_days_to_ia          = var.s3_lifecycle_days_to_ia
  s3_lifecycle_days_to_glacier     = var.s3_lifecycle_days_to_glacier
  s3_lifecycle_days_to_deep_archive = var.s3_lifecycle_days_to_deep_archive
  
  # Lambda configuration (if enabled)
  lambda_zip_path = var.lambda_zip_path

  # Tags
  common_tags = var.common_tags
}

# Additional AWS resources for enhanced monitoring (optional)
resource "aws_cloudwatch_log_group" "github_actions" {
  name              = "/aws/github-actions/${var.project_name}"
  retention_in_days = 7  # Minimal retention to reduce cost
  
  tags = var.common_tags
}

# Basic cost monitoring with CloudWatch alarms (free tier)
resource "aws_cloudwatch_metric_alarm" "budget_alarm" {
  count = length(var.admin_emails) > 0 ? 1 : 0
  
  alarm_name          = "${var.project_name}-budget-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # Daily check
  statistic           = "Maximum"
  threshold           = "4.0"    # Alert at $4 to stay under $5
  alarm_description   = "Alert when costs approach $5/month limit"

  dimensions = {
    Currency = "USD"
  }

  tags = var.common_tags
}

# Data for external integrations
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ====================
# Outputs
# ====================

output "ultra_low_cost_summary" {
  description = "Ultra-low-cost architecture summary"
  value = {
    estimated_monthly_costs = module.itsandbox_ultra_low_cost.estimated_monthly_costs
    cost_optimization_summary = module.itsandbox_ultra_low_cost.cost_optimization_summary
    deployment_instructions = module.itsandbox_ultra_low_cost.deployment_instructions
  }
}

output "github_repository_url" {
  description = "GitHub repository URL"
  value       = module.itsandbox_ultra_low_cost.github_repository_url
}

output "github_pages_url" {
  description = "GitHub Pages URL"
  value       = module.itsandbox_ultra_low_cost.github_pages_url
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.itsandbox_ultra_low_cost.cloudwatch_dashboard_url
}

output "architecture_comparison" {
  description = "Architecture comparison showing cost savings"
  value       = module.itsandbox_ultra_low_cost.architecture_comparison
}