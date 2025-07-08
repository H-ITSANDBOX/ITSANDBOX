# ITSANDBOX Production Environment
# 本番環境用のメインTerraform設定

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # S3バックエンド設定（後で設定）
  # backend "s3" {
  #   bucket         = "itsandbox-terraform-state"
  #   key            = "production/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "itsandbox-terraform-locks"
  # }
}

# ====================
# Provider Configuration
# ====================

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "ITSANDBOX"
      Environment = "Production"
      ManagedBy   = "Terraform"
      CostCenter  = "ITSANDBOX-Community"
      Owner       = "hoseiitsandbox@gmail.com"
    }
  }
}

# ====================
# Local Values
# ====================

locals {
  organization_name = "ITSANDBOX"
  environment      = "production"
  
  # 共通タグ
  common_tags = {
    Project     = "ITSANDBOX"
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "ITSANDBOX-Community"
    Owner       = "hoseiitsandbox@gmail.com"
  }
  
  # プロジェクト設定
  projects = {
    website = {
      project_lead_users = var.website_project_leads
      developer_users    = var.website_developers
      viewer_users       = var.website_viewers
      budget_limit       = "20"
      description        = "ITSANDBOX main website and frontend"
    }
    api = {
      project_lead_users = var.api_project_leads
      developer_users    = var.api_developers
      viewer_users       = var.api_viewers
      budget_limit       = "15"
      description        = "ITSANDBOX backend API and services"
    }
    infrastructure = {
      project_lead_users = var.infra_project_leads
      developer_users    = var.infra_developers
      viewer_users       = var.infra_viewers
      budget_limit       = "10"
      description        = "ITSANDBOX infrastructure and operations"
    }
    sandbox = {
      project_lead_users = var.sandbox_project_leads
      developer_users    = var.sandbox_developers
      viewer_users       = var.sandbox_viewers
      budget_limit       = "15"
      description        = "Individual development sandbox environments"
    }
  }
  
  # アカウント予算設定
  account_budgets = {
    "shared-services" = {
      limit              = "20"
      notification_emails = var.admin_emails
    }
    "security-audit" = {
      limit              = "10"
      notification_emails = var.admin_emails
    }
    "network-hub" = {
      limit              = "5"
      notification_emails = var.admin_emails
    }
    "website-project" = {
      limit              = "20"
      notification_emails = concat(var.admin_emails, var.website_project_leads)
    }
    "api-project" = {
      limit              = "15"
      notification_emails = concat(var.admin_emails, var.api_project_leads)
    }
    "infrastructure-project" = {
      limit              = "10"
      notification_emails = concat(var.admin_emails, var.infra_project_leads)
    }
    "sandbox-environments" = {
      limit              = "15"
      notification_emails = var.admin_emails
    }
  }
}

# ====================
# Cost Management Module
# ====================

module "cost_management" {
  source = "../../modules/cost-management"
  
  organization_budget_limit = var.organization_budget_limit
  admin_email_addresses    = var.admin_emails
  slack_webhook_url        = var.slack_webhook_url
  aws_region              = var.aws_region
  account_budgets         = local.account_budgets
  common_tags             = local.common_tags
  
  # コスト制御設定
  enable_cost_optimization = true
  daily_report_enabled    = true
  weekly_report_enabled   = true
  auto_stop_resources     = false  # 本番環境では無効
  
  # 予算アラート閾値
  budget_action_thresholds = {
    warning_threshold    = 70
    critical_threshold   = 85
    emergency_threshold  = 95
  }
  
  # リソース最適化ルール
  resource_optimization_rules = {
    stop_unused_ec2_instances   = false  # 本番環境では手動
    delete_unused_snapshots     = true
    optimize_s3_storage_class   = true
    right_size_rds_instances    = false  # 本番環境では手動
  }
}

# ====================
# IAM Management Module
# ====================

module "iam_management" {
  source = "../../modules/iam-management"
  
  organization_id      = var.organization_id
  master_account_id    = var.master_account_id
  trusted_account_ids  = var.trusted_account_ids
  project_account_ids  = var.project_account_ids
  external_id         = var.external_id
  
  allowed_regions = var.allowed_regions
  projects       = local.projects
  common_tags    = local.common_tags
  
  # セキュリティ設定
  mfa_required = true
  
  password_policy = {
    minimum_password_length        = 14
    require_lowercase_characters   = true
    require_numbers               = true
    require_symbols               = true
    require_uppercase_characters   = true
    allow_users_to_change_password = true
    max_password_age              = 90
    password_reuse_prevention     = 12
    hard_expiry                   = false
  }
  
  # 自動ユーザー管理
  auto_user_management = {
    auto_deactivate_unused_users = true
    unused_user_threshold_days   = 90
    auto_rotate_access_keys      = true
    access_key_rotation_days     = 90
  }
  
  # セキュリティ設定
  security_settings = {
    enable_cloudtrail_integration = true
    enable_access_analyzer        = true
    enable_credential_report      = true
    notification_email           = var.security_notification_email
  }
  
  # 開発制限
  development_restrictions = {
    allowed_instance_types    = ["t3.nano", "t3.micro", "t3.small"]
    max_instances_per_user   = 2
    auto_stop_after_hours    = 8
    allowed_storage_types    = ["gp3", "gp2"]
    max_storage_gb_per_user  = 50
  }
  
  # コスト制御設定
  cost_control_settings = {
    enforce_cost_tags          = true
    required_cost_tags         = ["Project", "Owner", "Environment", "CostCenter"]
    budget_alert_threshold     = 80
    auto_stop_on_budget_breach = false
  }
  
  # Lambda実行設定
  lambda_execution_settings = {
    max_execution_duration_minutes = 15
    allowed_runtime_versions      = ["python3.11", "python3.10", "nodejs18.x", "nodejs20.x"]
    max_memory_mb                = 1024
    vpc_config_required          = false
  }
}

# ====================
# Shared S3 Buckets
# ====================

# Terraform状態ファイル用S3バケット
resource "aws_s3_bucket" "terraform_state" {
  bucket = "itsandbox-terraform-state-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name        = "ITSANDBOX Terraform State"
    Purpose     = "TerraformState"
    Sensitivity = "High"
  })
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 共有リソース用S3バケット
resource "aws_s3_bucket" "shared_resources" {
  bucket = "itsandbox-shared-resources-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name    = "ITSANDBOX Shared Resources"
    Purpose = "SharedResources"
  })
}

resource "aws_s3_bucket_versioning" "shared_resources" {
  bucket = aws_s3_bucket.shared_resources.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "shared_resources" {
  bucket = aws_s3_bucket.shared_resources.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ====================
# DynamoDB for Terraform Locks
# ====================

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "itsandbox-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name    = "ITSANDBOX Terraform Locks"
    Purpose = "TerraformLocking"
  })
}

# ====================
# CloudWatch Dashboards
# ====================

resource "aws_cloudwatch_dashboard" "itsandbox_overview" {
  dashboard_name = "ITSANDBOX-Production-Overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Monthly Estimated Charges"
          period  = 86400
          stat    = "Maximum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { "stat": "Sum" }],
            ["AWS/Lambda", "Errors", { "stat": "Sum" }],
            ["AWS/Lambda", "Duration", { "stat": "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/lambda/itsandbox-cost-optimizer' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent Errors"
        }
      }
    ]
  })

  tags = local.common_tags
}

# ====================
# SNS Topics for Notifications
# ====================

resource "aws_sns_topic" "general_notifications" {
  name = "itsandbox-general-notifications"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "admin_email_notifications" {
  count = length(var.admin_emails)

  topic_arn = aws_sns_topic.general_notifications.arn
  protocol  = "email"
  endpoint  = var.admin_emails[count.index]
}

# ====================
# Route 53 Hosted Zone (Optional)
# ====================

resource "aws_route53_zone" "itsandbox" {
  count = var.create_hosted_zone ? 1 : 0
  
  name = var.domain_name

  tags = merge(local.common_tags, {
    Name = "ITSANDBOX Domain Zone"
  })
}

# ====================
# ACM Certificate (Optional)
# ====================

resource "aws_acm_certificate" "itsandbox" {
  count = var.create_ssl_certificate ? 1 : 0
  
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "ITSANDBOX SSL Certificate"
  })
}

# ====================
# Outputs
# ====================

output "cost_management_dashboard_url" {
  description = "URL of the cost management dashboard"
  value       = module.cost_management.cost_management_dashboard_url
}

output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "shared_resources_bucket" {
  description = "S3 bucket for shared resources"
  value       = aws_s3_bucket.shared_resources.bucket
}

output "iam_management_summary" {
  description = "Summary of IAM management configuration"
  value       = module.iam_management.automation_summary
}

output "admin_role_arn" {
  description = "ARN of the admin role for cross-account access"
  value       = module.iam_management.admin_role_arn
}

output "project_roles" {
  description = "Project-specific role ARNs"
  value       = module.iam_management.project_role_mapping
}

output "sns_topics" {
  description = "SNS topic ARNs for notifications"
  value = {
    general_notifications = aws_sns_topic.general_notifications.arn
    budget_alerts        = module.cost_management.budget_alerts_sns_topic_arn
    iam_notifications    = module.iam_management.iam_notifications_topic_arn
  }
}

output "lambda_functions" {
  description = "Lambda function ARNs"
  value = {
    cost_optimizer      = module.cost_management.cost_optimizer_lambda_arn
    user_management     = module.iam_management.user_management_lambda_arn
    user_onboarding     = module.iam_management.user_onboarding_lambda_arn
  }
}

output "cloudwatch_dashboard_url" {
  description = "URL of the main CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.itsandbox_overview.dashboard_name}"
}