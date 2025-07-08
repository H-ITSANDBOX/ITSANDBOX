# ITSANDBOX IAM Management Module Outputs

# ====================
# IAM Policies
# ====================

output "admin_policy_arn" {
  description = "ARN of the ITSANDBOX admin policy"
  value       = aws_iam_policy.itsandbox_admin_policy.arn
}

output "project_lead_policy_arn" {
  description = "ARN of the ITSANDBOX project lead policy"
  value       = aws_iam_policy.itsandbox_project_lead_policy.arn
}

output "developer_policy_arn" {
  description = "ARN of the ITSANDBOX developer policy"
  value       = aws_iam_policy.itsandbox_developer_policy.arn
}

output "viewer_policy_arn" {
  description = "ARN of the ITSANDBOX viewer policy"
  value       = aws_iam_policy.itsandbox_viewer_policy.arn
}

output "permissions_boundary_arn" {
  description = "ARN of the ITSANDBOX permissions boundary policy"
  value       = aws_iam_policy.itsandbox_permissions_boundary.arn
}

output "mfa_enforcement_policy_arn" {
  description = "ARN of the MFA enforcement policy"
  value       = aws_iam_policy.mfa_enforcement_policy.arn
}

# ====================
# IAM Roles
# ====================

output "admin_role_arn" {
  description = "ARN of the ITSANDBOX admin role"
  value       = aws_iam_role.itsandbox_admin_role.arn
}

output "project_lead_roles" {
  description = "ARNs of project lead roles by project"
  value       = { for k, v in aws_iam_role.itsandbox_project_lead_role : k => v.arn }
}

output "developer_roles" {
  description = "ARNs of developer roles by project"
  value       = { for k, v in aws_iam_role.itsandbox_developer_role : k => v.arn }
}

output "shared_services_role_arn" {
  description = "ARN of the shared services access role"
  value       = aws_iam_role.itsandbox_shared_services_role.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

# ====================
# IAM Groups
# ====================

output "admin_group_name" {
  description = "Name of the ITSANDBOX admins group"
  value       = aws_iam_group.itsandbox_admins.name
}

output "project_lead_group_name" {
  description = "Name of the ITSANDBOX project leads group"
  value       = aws_iam_group.itsandbox_project_leads.name
}

output "developer_group_name" {
  description = "Name of the ITSANDBOX developers group"
  value       = aws_iam_group.itsandbox_developers.name
}

output "viewer_group_name" {
  description = "Name of the ITSANDBOX viewers group"
  value       = aws_iam_group.itsandbox_viewers.name
}

# ====================
# Lambda Functions
# ====================

output "user_management_lambda_arn" {
  description = "ARN of the user management Lambda function"
  value       = aws_lambda_function.user_management.arn
}

output "user_onboarding_lambda_arn" {
  description = "ARN of the user onboarding Lambda function"
  value       = aws_lambda_function.user_onboarding.arn
}

output "user_management_lambda_name" {
  description = "Name of the user management Lambda function"
  value       = aws_lambda_function.user_management.function_name
}

output "user_onboarding_lambda_name" {
  description = "Name of the user onboarding Lambda function"
  value       = aws_lambda_function.user_onboarding.function_name
}

# ====================
# SNS Topics
# ====================

output "iam_notifications_topic_arn" {
  description = "ARN of the IAM notifications SNS topic"
  value       = aws_sns_topic.iam_notifications.arn
}

# ====================
# EventBridge Rules
# ====================

output "weekly_user_audit_rule_arn" {
  description = "ARN of the weekly user audit EventBridge rule"
  value       = aws_cloudwatch_event_rule.weekly_user_audit.arn
}

output "monthly_access_key_audit_rule_arn" {
  description = "ARN of the monthly access key audit EventBridge rule"
  value       = aws_cloudwatch_event_rule.monthly_access_key_audit.arn
}

# ====================
# Security Features
# ====================

output "access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer"
  value       = var.security_settings.enable_access_analyzer ? aws_accessanalyzer_analyzer.itsandbox_access_analyzer[0].arn : null
}

output "iam_events_log_group_name" {
  description = "Name of the IAM events CloudWatch log group"
  value       = var.security_settings.enable_cloudtrail_integration ? aws_cloudwatch_log_group.iam_events[0].name : null
}

# ====================
# Cross-Account Configuration
# ====================

output "cross_account_role_arns" {
  description = "ARNs for cross-account role assumption"
  value = {
    admin               = aws_iam_role.itsandbox_admin_role.arn
    shared_services     = aws_iam_role.itsandbox_shared_services_role.arn
    project_leads       = { for k, v in aws_iam_role.itsandbox_project_lead_role : k => v.arn }
    developers          = { for k, v in aws_iam_role.itsandbox_developer_role : k => v.arn }
  }
}

output "trust_policy_external_id" {
  description = "External ID used in trust policies"
  value       = var.external_id
  sensitive   = true
}

# ====================
# Password Policy
# ====================

output "password_policy_summary" {
  description = "Summary of the account password policy"
  value = {
    minimum_password_length        = var.password_policy.minimum_password_length
    require_lowercase_characters   = var.password_policy.require_lowercase_characters
    require_numbers               = var.password_policy.require_numbers
    require_symbols               = var.password_policy.require_symbols
    require_uppercase_characters   = var.password_policy.require_uppercase_characters
    max_password_age              = var.password_policy.max_password_age
    password_reuse_prevention     = var.password_policy.password_reuse_prevention
  }
}

# ====================
# Role Mapping
# ====================

output "role_to_group_mapping" {
  description = "Mapping of roles to IAM groups"
  value = {
    Admin       = aws_iam_group.itsandbox_admins.name
    ProjectLead = aws_iam_group.itsandbox_project_leads.name
    Developer   = aws_iam_group.itsandbox_developers.name
    Viewer      = aws_iam_group.itsandbox_viewers.name
  }
}

output "project_role_mapping" {
  description = "Mapping of projects to their roles"
  value = {
    for project, config in var.projects : project => {
      project_lead_role_arn = aws_iam_role.itsandbox_project_lead_role[project].arn
      developer_role_arn    = aws_iam_role.itsandbox_developer_role[project].arn
      budget_limit         = config.budget_limit
      description          = config.description
    }
  }
}

# ====================
# Automation Summary
# ====================

output "automation_summary" {
  description = "Summary of automated IAM management features"
  value = {
    user_management_enabled      = true
    auto_user_audit_enabled     = true
    access_key_rotation_enabled = var.auto_user_management.auto_rotate_access_keys
    mfa_enforcement_enabled     = var.mfa_required
    permissions_boundary_enabled = true
    access_analyzer_enabled     = var.security_settings.enable_access_analyzer
    cloudtrail_integration_enabled = var.security_settings.enable_cloudtrail_integration
    
    audit_schedules = {
      weekly_user_audit = aws_cloudwatch_event_rule.weekly_user_audit.schedule_expression
      monthly_key_audit = aws_cloudwatch_event_rule.monthly_access_key_audit.schedule_expression
    }
    
    thresholds = {
      unused_user_threshold_days = var.auto_user_management.unused_user_threshold_days
      access_key_rotation_days   = var.auto_user_management.access_key_rotation_days
    }
  }
}

# ====================
# Security Compliance
# ====================

output "compliance_status" {
  description = "Security compliance configuration status"
  value = {
    permissions_boundary_enforced = true
    mfa_policy_attached          = var.mfa_required
    password_policy_compliant    = true
    access_logging_enabled       = var.security_settings.enable_cloudtrail_integration
    access_analysis_enabled      = var.security_settings.enable_access_analyzer
    automated_auditing_enabled   = true
    cost_tagging_enforced       = var.cost_control_settings.enforce_cost_tags
    
    required_tags = var.cost_control_settings.required_cost_tags
    allowed_regions = var.allowed_regions
  }
}