# ITSANDBOX Master Account Infrastructure
# This file sets up the AWS Organization and master account configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# AWS Organization
resource "aws_organizations_organization" "itsandbox" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "account.amazonaws.com",
    "budgets.amazonaws.com",
  ]

  feature_set = "ALL"

  tags = {
    Name        = "ITSANDBOX Organization"
    Environment = "master"
    Project     = "ITSANDBOX"
  }
}

# Organizational Units
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.itsandbox.roots[0].id
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organization.itsandbox.roots[0].id
}

resource "aws_organizations_organizational_unit" "projects" {
  name      = "Projects"
  parent_id = aws_organizations_organization.itsandbox.roots[0].id
}

# Service Control Policies
resource "aws_organizations_policy" "cost_control" {
  name        = "ITSANDBOX-Cost-Control"
  description = "Cost control policy for ITSANDBOX"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "ec2:InstanceType" = [
              "t3.micro",
              "t3.small",
              "t3.medium"
            ]
          }
        }
      },
      {
        Effect = "Deny"
        Action = [
          "rds:CreateDBInstance"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "rds:DatabaseClass" = [
              "db.t3.micro",
              "db.t3.small"
            ]
          }
        }
      },
      {
        Effect = "Deny"
        Action = [
          "account:EnableRegion",
          "account:DisableRegion"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "us-east-1",
              "us-west-2",
              "ap-northeast-1"
            ]
          }
        }
      }
    ]
  })
}

# Budget for overall organization
resource "aws_budgets_budget" "organization_budget" {
  name         = "ITSANDBOX-Organization-Budget"
  budget_type  = "COST"
  limit_amount = "100"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filters = {
    TagKey = ["Project"]
    TagValue = ["ITSANDBOX"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type           = "PERCENTAGE"
    notification_type        = "ACTUAL"
    subscriber_email_addresses = [var.admin_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 90
    threshold_type           = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.admin_email]
  }
}

# CloudTrail for organization
resource "aws_cloudtrail" "organization_trail" {
  name                          = "itsandbox-organization-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail        = true
  is_organization_trail        = true
  enable_log_file_validation   = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]

  tags = {
    Name        = "ITSANDBOX Organization Trail"
    Environment = "master"
    Project     = "ITSANDBOX"
  }
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "itsandbox-cloudtrail-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "ITSANDBOX CloudTrail Logs"
    Environment = "master"
    Project     = "ITSANDBOX"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Cost monitoring Lambda function
resource "aws_lambda_function" "cost_monitor" {
  filename         = "cost_monitor.zip"
  function_name    = "itsandbox-cost-monitor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      BUDGET_LIMIT = "100"
      ADMIN_EMAIL  = var.admin_email
    }
  }

  tags = {
    Name        = "ITSANDBOX Cost Monitor"
    Environment = "master"
    Project     = "ITSANDBOX"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "itsandbox-cost-monitor-role"

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
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "itsandbox-cost-monitor-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetUsageReport",
          "budgets:ViewBudget",
          "budgets:ModifyBudget",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule for daily cost monitoring
resource "aws_cloudwatch_event_rule" "daily_cost_check" {
  name                = "itsandbox-daily-cost-check"
  description         = "Daily cost monitoring for ITSANDBOX"
  schedule_expression = "rate(1 day)"

  tags = {
    Name        = "ITSANDBOX Daily Cost Check"
    Environment = "master"
    Project     = "ITSANDBOX"
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_cost_check.name
  target_id = "CostMonitorLambda"
  arn       = aws_lambda_function.cost_monitor.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cost_check.arn
}

# SNS topic for alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "itsandbox-cost-alerts"

  tags = {
    Name        = "ITSANDBOX Cost Alerts"
    Environment = "master"
    Project     = "ITSANDBOX"
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "cost_dashboard" {
  dashboard_name = "ITSANDBOX-Cost-Dashboard"

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
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          period = 86400
          stat   = "Maximum"
          region = "us-east-1"
          title  = "Total Estimated Charges"
        }
      }
    ]
  })
}