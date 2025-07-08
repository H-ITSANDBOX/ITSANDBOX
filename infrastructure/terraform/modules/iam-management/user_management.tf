# ITSANDBOX User Management and Automation

# ====================
# Account Password Policy
# ====================

resource "aws_iam_account_password_policy" "itsandbox_password_policy" {
  minimum_password_length        = var.password_policy.minimum_password_length
  require_lowercase_characters   = var.password_policy.require_lowercase_characters
  require_numbers               = var.password_policy.require_numbers
  require_symbols               = var.password_policy.require_symbols
  require_uppercase_characters   = var.password_policy.require_uppercase_characters
  allow_users_to_change_password = var.password_policy.allow_users_to_change_password
  max_password_age              = var.password_policy.max_password_age
  password_reuse_prevention     = var.password_policy.password_reuse_prevention
  hard_expiry                   = var.password_policy.hard_expiry
}

# ====================
# User Management Lambda Function
# ====================

resource "aws_lambda_function" "user_management" {
  filename         = data.archive_file.user_management_zip.output_path
  function_name    = "itsandbox-user-management"
  role            = aws_iam_role.user_management_lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.user_management_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 300

  environment {
    variables = {
      ORGANIZATION_ID              = var.organization_id
      MASTER_ACCOUNT_ID           = var.master_account_id
      UNUSED_USER_THRESHOLD_DAYS  = var.auto_user_management.unused_user_threshold_days
      ACCESS_KEY_ROTATION_DAYS    = var.auto_user_management.access_key_rotation_days
      NOTIFICATION_EMAIL          = var.security_settings.notification_email
      SNS_TOPIC_ARN              = aws_sns_topic.iam_notifications.arn
    }
  }

  tags = var.common_tags
}

# Lambda実行用IAMロール
resource "aws_iam_role" "user_management_lambda_role" {
  name = "ITSANDBOXUserManagementLambdaRole"
  path = "/itsandbox/"

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

resource "aws_iam_role_policy" "user_management_lambda_policy" {
  name = "ITSANDBOXUserManagementLambdaPolicy"
  role = aws_iam_role.user_management_lambda_role.id

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
          "iam:ListUsers",
          "iam:GetUser",
          "iam:GetUserLastAccessed",
          "iam:ListAccessKeys",
          "iam:UpdateAccessKey",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListUserTags",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:GenerateCredentialReport",
          "iam:GetCredentialReport"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.iam_notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ses:FromAddress": var.security_settings.notification_email
          }
        }
      }
    ]
  })
}

# Lambda function code
data "archive_file" "user_management_zip" {
  type        = "zip"
  output_path = "${path.module}/user_management.zip"
  
  source {
    content = templatefile("${path.module}/lambda/user_management.py", {
      notification_email = var.security_settings.notification_email
    })
    filename = "index.py"
  }
}

# ====================
# User Onboarding Lambda Function
# ====================

resource "aws_lambda_function" "user_onboarding" {
  filename         = data.archive_file.user_onboarding_zip.output_path
  function_name    = "itsandbox-user-onboarding"
  role            = aws_iam_role.user_onboarding_lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.user_onboarding_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 300

  environment {
    variables = {
      ADMIN_GROUP_NAME       = aws_iam_group.itsandbox_admins.name
      PROJECT_LEAD_GROUP_NAME = aws_iam_group.itsandbox_project_leads.name
      DEVELOPER_GROUP_NAME   = aws_iam_group.itsandbox_developers.name
      VIEWER_GROUP_NAME      = aws_iam_group.itsandbox_viewers.name
      NOTIFICATION_EMAIL     = var.security_settings.notification_email
      SNS_TOPIC_ARN         = aws_sns_topic.iam_notifications.arn
      EXTERNAL_ID           = var.external_id
    }
  }

  tags = var.common_tags
}

# User onboarding Lambda実行用IAMロール
resource "aws_iam_role" "user_onboarding_lambda_role" {
  name = "ITSANDBOXUserOnboardingLambdaRole"
  path = "/itsandbox/"

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

resource "aws_iam_role_policy" "user_onboarding_lambda_policy" {
  name = "ITSANDBOXUserOnboardingLambdaPolicy"
  role = aws_iam_role.user_onboarding_lambda_role.id

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
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:GetUser",
          "iam:AddUserToGroup",
          "iam:RemoveUserFromGroup",
          "iam:ListGroupsForUser",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:CreateLoginProfile",
          "iam:DeleteLoginProfile",
          "iam:UpdateLoginProfile",
          "iam:PutUserPermissionsBoundary"
        ]
        Resource = [
          "arn:aws:iam::*:user/itsandbox-*",
          "arn:aws:iam::*:group/ITSANDBOX*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.iam_notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ses:FromAddress": var.security_settings.notification_email
          }
        }
      }
    ]
  })
}

# User onboarding function code
data "archive_file" "user_onboarding_zip" {
  type        = "zip"
  output_path = "${path.module}/user_onboarding.zip"
  
  source {
    content = templatefile("${path.module}/lambda/user_onboarding.py", {
      notification_email = var.security_settings.notification_email
      external_id       = var.external_id
    })
    filename = "index.py"
  }
}

# ====================
# SNS Topic for IAM Notifications
# ====================

resource "aws_sns_topic" "iam_notifications" {
  name = "itsandbox-iam-notifications"

  tags = var.common_tags
}

resource "aws_sns_topic_subscription" "iam_email_notification" {
  topic_arn = aws_sns_topic.iam_notifications.arn
  protocol  = "email"
  endpoint  = var.security_settings.notification_email
}

# ====================
# EventBridge Rules for User Management
# ====================

# 週次ユーザー監査
resource "aws_cloudwatch_event_rule" "weekly_user_audit" {
  name                = "itsandbox-weekly-user-audit"
  description         = "Weekly user access audit"
  schedule_expression = "cron(0 9 ? * MON *)"  # 毎週月曜日9:00 UTC

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "user_audit_lambda_target" {
  rule      = aws_cloudwatch_event_rule.weekly_user_audit.name
  target_id = "TriggerUserManagementLambda"
  arn       = aws_lambda_function.user_management.arn

  input = jsonencode({
    action = "audit_users"
  })
}

resource "aws_lambda_permission" "allow_eventbridge_user_audit" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_management.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_user_audit.arn
}

# 月次アクセスキー監査
resource "aws_cloudwatch_event_rule" "monthly_access_key_audit" {
  name                = "itsandbox-monthly-access-key-audit"
  description         = "Monthly access key rotation audit"
  schedule_expression = "cron(0 10 1 * ? *)"  # 毎月1日10:00 UTC

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "access_key_audit_lambda_target" {
  rule      = aws_cloudwatch_event_rule.monthly_access_key_audit.name
  target_id = "TriggerAccessKeyAuditLambda"
  arn       = aws_lambda_function.user_management.arn

  input = jsonencode({
    action = "audit_access_keys"
  })
}

resource "aws_lambda_permission" "allow_eventbridge_access_key_audit" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_management.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_access_key_audit.arn
}

# ====================
# IAM Access Analyzer
# ====================

resource "aws_accessanalyzer_analyzer" "itsandbox_access_analyzer" {
  count = var.security_settings.enable_access_analyzer ? 1 : 0

  analyzer_name = "ITSANDBOXAccessAnalyzer"
  type         = "ACCOUNT"

  tags = var.common_tags
}

# ====================
# CloudTrail Integration for IAM Events
# ====================

resource "aws_cloudwatch_log_group" "iam_events" {
  count = var.security_settings.enable_cloudtrail_integration ? 1 : 0

  name              = "/aws/events/itsandbox-iam"
  retention_in_days = 90

  tags = var.common_tags
}

resource "aws_cloudwatch_event_rule" "iam_events" {
  count = var.security_settings.enable_cloudtrail_integration ? 1 : 0

  name        = "itsandbox-iam-events"
  description = "Capture IAM-related events"

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = [
      "AWS API Call via CloudTrail"
    ]
    detail = {
      eventSource = ["iam.amazonaws.com"]
      eventName = [
        "CreateUser",
        "DeleteUser",
        "CreateRole",
        "DeleteRole",
        "AttachUserPolicy",
        "DetachUserPolicy",
        "CreateAccessKey",
        "DeleteAccessKey"
      ]
    }
  })

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "iam_events_log_group" {
  count = var.security_settings.enable_cloudtrail_integration ? 1 : 0

  rule      = aws_cloudwatch_event_rule.iam_events[0].name
  target_id = "SendToCloudWatchLogs"
  arn       = aws_cloudwatch_log_group.iam_events[0].arn
}