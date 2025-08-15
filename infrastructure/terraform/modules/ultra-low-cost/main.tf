# ITSANDBOX Ultra-Low-Cost Infrastructure ($0-5/month)
# GitHub Pages + 最小AWS構成

terraform {
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
}

# ====================
# GitHub Repository for Static Hosting
# ====================

resource "github_repository" "itsandbox" {
  name         = var.repository_name
  description  = "ITSANDBOX - 法政大学ITイノベーションコミュニティ (Ultra-Low-Cost)"
  visibility   = "public"
  
  has_issues   = true
  has_projects = true
  has_wiki     = true
  
  # Enable GitHub Pages
  pages {
    source {
      branch = "gh-pages"
      path   = "/"
    }
  }
  
  # Repository settings
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  delete_branch_on_merge = true
  
  # Security
  vulnerability_alerts = true
  
  topics = [
    "itsandbox",
    "hosei-university",
    "react",
    "typescript",
    "ultra-low-cost",
    "github-pages"
  ]
}

# ====================
# GitHub Actions Secrets for Deployment
# ====================

resource "github_actions_secret" "aws_access_key" {
  repository      = github_repository.itsandbox.name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.aws_access_key_id
}

resource "github_actions_secret" "aws_secret_key" {
  repository      = github_repository.itsandbox.name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.aws_secret_access_key
}

resource "github_actions_secret" "notification_webhook" {
  repository      = github_repository.itsandbox.name
  secret_name     = "NOTIFICATION_WEBHOOK_URL"
  plaintext_value = var.notification_webhook_url
}

# ====================
# Minimal AWS Lambda for Critical Functions Only
# ====================

# Single Lambda function for essential backend operations
resource "aws_lambda_function" "essential_backend" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_name}-essential-${var.environment}"
  role            = aws_iam_role.lambda_minimal[0].arn
  handler         = "index.handler"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime         = "nodejs18.x"  # Node.js for smaller package size
  architectures   = ["arm64"]     # Cheaper than x86_64
  timeout         = 10            # Short timeout to minimize cost
  memory_size     = 128           # Minimum memory

  environment {
    variables = {
      ENVIRONMENT     = var.environment
      BUDGET_LIMIT    = "5.0"
      NOTIFICATION_URL = var.notification_webhook_url
    }
  }

  # Only create if specifically needed
  count = var.enable_lambda_backend ? 1 : 0

  tags = var.common_tags
}

# Minimal IAM role for Lambda
resource "aws_iam_role" "lambda_minimal" {
  count = var.enable_lambda_backend ? 1 : 0
  name  = "${var.project_name}-lambda-minimal-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_minimal_basic" {
  count      = var.enable_lambda_backend ? 1 : 0
  role       = aws_iam_role.lambda_minimal[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ====================
# CloudWatch Budget Alert (Free tier)
# ====================

resource "aws_budgets_budget" "ultra_low_cost" {
  name         = "${var.project_name}-ultra-low-cost-budget"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filter {
    name   = "Service"
    values = ["Amazon Simple Storage Service", "AWS Lambda", "Amazon CloudWatch", "Amazon Simple Notification Service"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.admin_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.admin_emails
  }

  tags = var.common_tags
}

# ====================
# Route 53 Domain (Optional - only if free domain available)
# ====================

resource "aws_route53_zone" "main" {
  count = var.enable_custom_domain && var.domain_name != null ? 1 : 0
  name  = var.domain_name

  tags = merge(var.common_tags, {
    Name = "ITSANDBOX Domain Zone"
    Note = "Consider GitHub Pages custom domain for $0 cost"
  })
}

# CNAME record pointing to GitHub Pages
resource "aws_route53_record" "github_pages" {
  count   = var.enable_custom_domain && var.domain_name != null ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.github_username}.github.io"]
}

# ====================
# S3 Bucket for Backup/Static Assets (Lifecycle management)
# ====================

resource "aws_s3_bucket" "backup" {
  bucket = "${var.project_name}-backup-${var.environment}-${random_id.suffix.hex}"

  tags = merge(var.common_tags, {
    Name    = "ITSANDBOX Backup Storage"
    Purpose = "Backup and Static Assets"
    Note    = "Minimize usage to stay in free tier"
  })
}

# Lifecycle configuration to minimize costs
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "transition_to_ia"
    status = "Enabled"
    
    filter {
      prefix = ""
    }

    transition {
      days          = var.s3_lifecycle_days_to_ia
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.s3_lifecycle_days_to_glacier
      storage_class = "GLACIER"
    }

    transition {
      days          = var.s3_lifecycle_days_to_deep_archive
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555  # 7 years
    }
  }

  rule {
    id     = "delete_incomplete_multipart"
    status = "Enabled"
    
    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ====================
# CloudWatch Dashboard (Free tier)
# ====================

resource "aws_cloudwatch_dashboard" "ultra_low_cost" {
  dashboard_name = "${var.project_name}-ultra-low-cost-monitoring"

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
          title   = "Ultra-Low-Cost Monthly Charges (Target: <$5)"
          period  = 86400
          stat    = "Maximum"
          yAxis = {
            left = {
              min = 0
              max = 5
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = var.enable_lambda_backend ? [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.essential_backend[0].function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.essential_backend[0].function_name],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.essential_backend[0].function_name]
          ] : []
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Metrics (If Enabled)"
          period  = 300
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 6
        width  = 24
        height = 2

        properties = {
          markdown = "## ITSANDBOX Ultra-Low-Cost Architecture\n\n**Primary Hosting**: GitHub Pages (Free)\n**Backup Services**: Minimal AWS ($0-5/month)\n**Target**: 90%+ cost reduction from previous architecture"
        }
      }
    ]
  })
}

# ====================
# SNS Topic for Critical Alerts (Free tier)
# ====================

resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project_name}-critical-alerts-${var.environment}"

  tags = merge(var.common_tags, {
    Name = "ITSANDBOX Critical Alerts"
    Note = "Use sparingly to stay in free tier"
  })
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count = length(var.admin_emails)

  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_emails[count.index]
}

# ====================
# CloudWatch Alarms for Budget Monitoring
# ====================

resource "aws_cloudwatch_metric_alarm" "budget_alarm" {
  alarm_name          = "${var.project_name}-budget-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # Daily
  statistic           = "Maximum"
  threshold           = "4.0"    # Alert at $4 to stay under $5
  alarm_description   = "This metric monitors AWS charges to stay under $5/month"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = var.common_tags
}

# ====================
# GitHub Actions Workflow for Deployment
# ====================

resource "github_repository_file" "deploy_workflow" {
  repository = github_repository.itsandbox.name
  branch     = "main"
  file       = ".github/workflows/deploy.yml"
  
  content = <<-EOT
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        run: cd frontend && npm ci

      - name: Build
        run: cd frontend && npm run build
        env:
          REACT_APP_ENVIRONMENT: production
          REACT_APP_COST_LIMIT: "5.0"
          REACT_APP_ENABLE_MOCK_API: "true"

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: frontend/dist

  deploy:
    environment:
      name: github-pages
      url: $${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4

  notify:
    if: always()
    runs-on: ubuntu-latest
    needs: [build, deploy]
    
    steps:
      - name: Notify deployment status
        run: |
          if [ "$${{ needs.deploy.result }}" = "success" ]; then
            echo "🎉 ITSANDBOX deployed successfully to GitHub Pages!"
            echo "📊 Estimated cost: <$$1/month (GitHub Pages is free)"
          else
            echo "❌ Deployment failed"
          fi
  EOT
}

# ====================
# Random ID for unique naming
# ====================

resource "random_id" "suffix" {
  byte_length = 2
}