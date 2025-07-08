# ITSANDBOX Cost Management Module
# 月額$100予算の厳格な管理とアラート設定

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ====================
# Budget Configuration
# ====================

# Organization全体の月額予算設定
resource "aws_budgets_budget" "itsandbox_organization_budget" {
  name              = "ITSANDBOX-Organization-Monthly-Budget"
  budget_type       = "COST"
  limit_amount      = var.organization_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Service = ["Amazon Elastic Compute Cloud - Compute"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 70
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.admin_email_addresses
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 85
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.admin_email_addresses
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 95
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.admin_email_addresses
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  depends_on = [aws_sns_topic.budget_alerts]

  tags = var.common_tags
}

# Account別予算設定
resource "aws_budgets_budget" "account_budgets" {
  for_each = var.account_budgets

  name              = "ITSANDBOX-${each.key}-Monthly-Budget"
  budget_type       = "COST"
  limit_amount      = each.value.limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = concat(var.admin_email_addresses, each.value.notification_emails)
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = concat(var.admin_email_addresses, each.value.notification_emails)
    subscriber_sns_topic_arns  = [aws_sns_topic.critical_alerts.arn]
  }

  tags = merge(var.common_tags, {
    Account = each.key
    Budget  = each.value.limit
  })
}

# ====================
# SNS Configuration
# ====================

# 予算アラート用SNSトピック
resource "aws_sns_topic" "budget_alerts" {
  name = "itsandbox-budget-alerts"

  tags = var.common_tags
}

# 緊急アラート用SNSトピック
resource "aws_sns_topic" "critical_alerts" {
  name = "itsandbox-critical-budget-alerts"

  tags = var.common_tags
}

# SNSトピック購読設定
resource "aws_sns_topic_subscription" "budget_alert_email" {
  count = length(var.admin_email_addresses)

  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email_addresses[count.index]
}

resource "aws_sns_topic_subscription" "critical_alert_email" {
  count = length(var.admin_email_addresses)

  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email_addresses[count.index]
}

# Slack通知用Webhook（オプション）
resource "aws_sns_topic_subscription" "slack_webhook" {
  count = var.slack_webhook_url != "" ? 1 : 0

  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}

# ====================
# CloudWatch Dashboard
# ====================

resource "aws_cloudwatch_dashboard" "cost_management" {
  dashboard_name = "ITSANDBOX-Cost-Management"

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
          region  = "us-east-1"
          title   = "Monthly Estimated Charges"
          period  = 86400
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/lambda/cost-optimization' | fields @timestamp, @message | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Cost Optimization Logs"
        }
      }
    ]
  })

  tags = var.common_tags
}

# ====================
# Cost Anomaly Detection
# ====================

resource "aws_ce_anomaly_detector" "itsandbox_cost_anomaly" {
  name         = "ITSANDBOX-Cost-Anomaly-Detector"
  monitor_type = "DIMENSIONAL"

  specification = jsonencode({
    Dimension = "SERVICE"
    MatchOptions = ["EQUALS"]
    Values = ["EC2-Instance", "AmazonS3", "AWSLambda", "AmazonRDS"]
  })

  tags = var.common_tags
}

resource "aws_ce_anomaly_subscription" "itsandbox_anomaly_subscription" {
  name      = "ITSANDBOX-Anomaly-Subscription"
  frequency = "DAILY"
  
  monitor_arn_list = [
    aws_ce_anomaly_detector.itsandbox_cost_anomaly.arn
  ]

  subscriber {
    type    = "EMAIL"
    address = var.admin_email_addresses[0]
  }

  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = ["10"]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }

  tags = var.common_tags
}

# ====================
# Lambda Functions for Cost Management
# ====================

# Cost optimization analysis function
resource "aws_lambda_function" "cost_optimizer" {
  filename         = data.archive_file.cost_optimizer_zip.output_path
  function_name    = "itsandbox-cost-optimizer"
  role            = aws_iam_role.lambda_cost_optimizer.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.cost_optimizer_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 300

  environment {
    variables = {
      ORGANIZATION_BUDGET = var.organization_budget_limit
      SNS_TOPIC_ARN      = aws_sns_topic.budget_alerts.arn
      SLACK_WEBHOOK_URL  = var.slack_webhook_url
    }
  }

  tags = var.common_tags
}

# Lambda実行用IAMロール
resource "aws_iam_role" "lambda_cost_optimizer" {
  name = "itsandbox-cost-optimizer-role"

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

resource "aws_iam_role_policy" "lambda_cost_optimizer_policy" {
  name = "itsandbox-cost-optimizer-policy"
  role = aws_iam_role.lambda_cost_optimizer.id

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
          "ce:GetDimensionValues",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetReservationUtilization",
          "ce:GetUsageReport",
          "budgets:ViewBudget",
          "budgets:ModifyBudget"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.budget_alerts.arn,
          aws_sns_topic.critical_alerts.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "rds:DescribeDBInstances",
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function code archive
data "archive_file" "cost_optimizer_zip" {
  type        = "zip"
  output_path = "${path.module}/cost_optimizer.zip"
  
  source {
    content = templatefile("${path.module}/lambda/cost_optimizer.py", {
      organization_budget = var.organization_budget_limit
    })
    filename = "index.py"
  }
}

# ====================
# EventBridge Scheduling
# ====================

# 日次コスト分析スケジュール
resource "aws_cloudwatch_event_rule" "daily_cost_analysis" {
  name                = "itsandbox-daily-cost-analysis"
  description         = "Trigger daily cost analysis"
  schedule_expression = "cron(0 9 * * ? *)"  # 毎日9:00 UTC

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_cost_analysis.name
  target_id = "TriggerCostOptimizerLambda"
  arn       = aws_lambda_function.cost_optimizer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimizer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cost_analysis.arn
}

# ====================
# Cost Allocation Tags
# ====================

resource "aws_ce_cost_category" "itsandbox_projects" {
  name         = "ITSANDBOX-Projects"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = "Project-Website"
    rule {
      dimension {
        key           = "TAG"
        values        = ["itsandbox-website"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Project-API"
    rule {
      dimension {
        key           = "TAG"
        values        = ["itsandbox-api"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Individual-Sandbox"
    rule {
      dimension {
        key           = "TAG"
        values        = ["individual-sandbox"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Shared-Services"
    rule {
      dimension {
        key           = "TAG"
        values        = ["shared-services"]
        match_options = ["EQUALS"]
      }
    }
  }

  tags = var.common_tags
}