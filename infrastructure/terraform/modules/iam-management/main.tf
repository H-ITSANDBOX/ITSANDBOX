# ITSANDBOX IAM権限管理モジュール
# Role-Based Access Control (RBAC) システム

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
# IAM Policies for ITSANDBOX Roles
# ====================

# 管理者用ポリシー
resource "aws_iam_policy" "itsandbox_admin_policy" {
  name        = "ITSANDBOXAdminPolicy"
  description = "Full administrative access for ITSANDBOX administrators"
  path        = "/itsandbox/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "organizations:*",
          "account:*",
          "billing:*",
          "budgets:*",
          "ce:*",
          "iam:*",
          "sts:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion": var.allowed_regions
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "support:*",
          "trustedadvisor:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# プロジェクトリーダー用ポリシー
resource "aws_iam_policy" "itsandbox_project_lead_policy" {
  name        = "ITSANDBOXProjectLeadPolicy"
  description = "Project leadership permissions for ITSANDBOX project leaders"
  path        = "/itsandbox/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:*",
          "s3:*",
          "dynamodb:*",
          "apigateway:*",
          "cloudformation:*",
          "cloudwatch:*",
          "logs:*",
          "events:*",
          "sns:*",
          "sqs:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Project": "$${aws:PrincipalTag/Project}",
            "aws:RequestedRegion": var.allowed_regions
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRole",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/itsandbox-*",
          "arn:aws:iam::*:role/lambda-*"
        ]
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary": aws_iam_policy.itsandbox_permissions_boundary.arn
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# 開発者用ポリシー
resource "aws_iam_policy" "itsandbox_developer_policy" {
  name        = "ITSANDBOXDeveloperPolicy"
  description = "Development permissions for ITSANDBOX developers"
  path        = "/itsandbox/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:InvokeFunction",
          "lambda:GetFunction",
          "lambda:ListFunctions",
          "lambda:DeleteFunction"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Project": "$${aws:PrincipalTag/Project}",
            "aws:RequestTag/Environment": ["development", "staging"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::itsandbox-*",
          "arn:aws:s3:::itsandbox-*/*"
        ]
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/Project": "$${aws:PrincipalTag/Project}"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/itsandbox-*"
        Condition = {
          StringEquals = {
            "dynamodb:Attributes": [
              "project",
              "owner",
              "data"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "ec2:StartInstances",
          "rds:CreateDBInstance",
          "elasticache:CreateCacheCluster"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalTag/Role": ["Admin", "ProjectLead"]
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# 閲覧者用ポリシー
resource "aws_iam_policy" "itsandbox_viewer_policy" {
  name        = "ITSANDBOXViewerPolicy"
  description = "Read-only permissions for ITSANDBOX viewers"
  path        = "/itsandbox/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:ListFunctions",
          "s3:GetObject",
          "s3:ListBucket",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion": var.allowed_regions
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "ce:GetCostAndUsage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# Permissions Boundary (権限境界)
resource "aws_iam_policy" "itsandbox_permissions_boundary" {
  name        = "ITSANDBOXPermissionsBoundary"
  description = "Permissions boundary for all ITSANDBOX users"
  path        = "/itsandbox/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:*",
          "s3:*",
          "dynamodb:*",
          "apigateway:*",
          "cloudformation:*",
          "cloudwatch:*",
          "logs:*",
          "events:*",
          "sns:*",
          "sqs:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion": var.allowed_regions
          }
        }
      },
      {
        Effect = "Deny"
        Action = [
          "organizations:*",
          "account:*",
          "billing:*",
          "support:*",
          "trustedadvisor:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalTag/Role": "Admin"
          }
        }
      },
      {
        Effect = "Deny"
        Action = [
          "ec2:*",
          "rds:*",
          "elasticache:*",
          "redshift:*",
          "emr:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalTag/Role": ["Admin", "ProjectLead"]
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# ====================
# IAM Roles
# ====================

# 管理者ロール
resource "aws_iam_role" "itsandbox_admin_role" {
  name               = "ITSANDBOXAdminRole"
  path               = "/itsandbox/"
  permissions_boundary = aws_iam_policy.itsandbox_permissions_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            for account_id in var.trusted_account_ids :
            "arn:aws:iam::${account_id}:root"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId": var.external_id
          }
          MfaPresent = "true"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Role = "Admin"
  })
}

resource "aws_iam_role_policy_attachment" "admin_policy_attachment" {
  role       = aws_iam_role.itsandbox_admin_role.name
  policy_arn = aws_iam_policy.itsandbox_admin_policy.arn
}

# プロジェクトリーダーロール
resource "aws_iam_role" "itsandbox_project_lead_role" {
  for_each = var.projects

  name               = "ITSANDBOXProjectLead-${each.key}"
  path               = "/itsandbox/"
  permissions_boundary = aws_iam_policy.itsandbox_permissions_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = each.value.project_lead_users
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId": var.external_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Role    = "ProjectLead"
    Project = each.key
  })
}

resource "aws_iam_role_policy_attachment" "project_lead_policy_attachment" {
  for_each = var.projects

  role       = aws_iam_role.itsandbox_project_lead_role[each.key].name
  policy_arn = aws_iam_policy.itsandbox_project_lead_policy.arn
}

# 開発者ロール
resource "aws_iam_role" "itsandbox_developer_role" {
  for_each = var.projects

  name               = "ITSANDBOXDeveloper-${each.key}"
  path               = "/itsandbox/"
  permissions_boundary = aws_iam_policy.itsandbox_permissions_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = each.value.developer_users
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId": var.external_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Role    = "Developer"
    Project = each.key
  })
}

resource "aws_iam_role_policy_attachment" "developer_policy_attachment" {
  for_each = var.projects

  role       = aws_iam_role.itsandbox_developer_role[each.key].name
  policy_arn = aws_iam_policy.itsandbox_developer_policy.arn
}

# ====================
# Cross-Account Roles
# ====================

# 共有サービスアクセス用ロール
resource "aws_iam_role" "itsandbox_shared_services_role" {
  name = "ITSANDBOXSharedServicesRole"
  path = "/itsandbox/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            for account_id in var.project_account_ids :
            "arn:aws:iam::${account_id}:root"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId": var.external_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Role = "SharedServices"
  })
}

resource "aws_iam_policy" "shared_services_access_policy" {
  name = "ITSANDBOXSharedServicesAccessPolicy"
  path = "/itsandbox/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:*",
          "acm:*",
          "cloudfront:*",
          "ecr:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::itsandbox-shared-*",
          "arn:aws:s3:::itsandbox-shared-*/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "shared_services_policy_attachment" {
  role       = aws_iam_role.itsandbox_shared_services_role.name
  policy_arn = aws_iam_policy.shared_services_access_policy.arn
}

# ====================
# IAM Groups
# ====================

# 管理者グループ
resource "aws_iam_group" "itsandbox_admins" {
  name = "ITSANDBOXAdmins"
  path = "/itsandbox/"
}

resource "aws_iam_group_policy_attachment" "admin_group_policy" {
  group      = aws_iam_group.itsandbox_admins.name
  policy_arn = aws_iam_policy.itsandbox_admin_policy.arn
}

# プロジェクトリーダーグループ
resource "aws_iam_group" "itsandbox_project_leads" {
  name = "ITSANDBOXProjectLeads"
  path = "/itsandbox/"
}

resource "aws_iam_group_policy_attachment" "project_lead_group_policy" {
  group      = aws_iam_group.itsandbox_project_leads.name
  policy_arn = aws_iam_policy.itsandbox_project_lead_policy.arn
}

# 開発者グループ
resource "aws_iam_group" "itsandbox_developers" {
  name = "ITSANDBOXDevelopers"
  path = "/itsandbox/"
}

resource "aws_iam_group_policy_attachment" "developer_group_policy" {
  group      = aws_iam_group.itsandbox_developers.name
  policy_arn = aws_iam_policy.itsandbox_developer_policy.arn
}

# 閲覧者グループ
resource "aws_iam_group" "itsandbox_viewers" {
  name = "ITSANDBOXViewers"
  path = "/itsandbox/"
}

resource "aws_iam_group_policy_attachment" "viewer_group_policy" {
  group      = aws_iam_group.itsandbox_viewers.name
  policy_arn = aws_iam_policy.itsandbox_viewer_policy.arn
}

# ====================
# Lambda Execution Roles
# ====================

# Lambda基本実行ロール
resource "aws_iam_role" "lambda_execution_role" {
  name = "ITSANDBOXLambdaExecutionRole"
  path = "/itsandbox/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ====================
# MFA Policy
# ====================

resource "aws_iam_policy" "mfa_enforcement_policy" {
  name = "ITSANDBOXMFAEnforcementPolicy"
  path = "/itsandbox/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewAccountInfo"
        Effect = "Allow"
        Action = [
          "iam:GetAccountPasswordPolicy",
          "iam:GetAccountSummary",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowManageOwnPasswords"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnMFA"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice"
        ]
        Resource = [
          "arn:aws:iam::*:mfa/$${aws:username}",
          "arn:aws:iam::*:user/$${aws:username}"
        ]
      },
      {
        Sid    = "DenyAllExceptUnlessMFAAuthenticated"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}