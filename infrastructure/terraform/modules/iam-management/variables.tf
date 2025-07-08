# ITSANDBOX IAM Management Module Variables

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "master_account_id" {
  description = "Master account ID for the organization"
  type        = string
}

variable "trusted_account_ids" {
  description = "List of trusted AWS account IDs that can assume roles"
  type        = list(string)
  default     = []
}

variable "project_account_ids" {
  description = "List of project account IDs"
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  sensitive   = true
}

variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["us-east-1", "ap-northeast-1"]
}

variable "projects" {
  description = "Project configuration with team members"
  type = map(object({
    project_lead_users = list(string)
    developer_users    = list(string)
    viewer_users       = list(string)
    budget_limit       = string
    description        = string
  }))
  default = {
    "website" = {
      project_lead_users = []
      developer_users    = []
      viewer_users       = []
      budget_limit       = "20"
      description        = "ITSANDBOX main website project"
    }
    "api" = {
      project_lead_users = []
      developer_users    = []
      viewer_users       = []
      budget_limit       = "15"
      description        = "ITSANDBOX API backend project"
    }
    "sandbox" = {
      project_lead_users = []
      developer_users    = []
      viewer_users       = []
      budget_limit       = "10"
      description        = "Individual sandbox environments"
    }
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "ITSANDBOX"
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "ITSANDBOX-Community"
    Owner       = "hoseiitsandbox@gmail.com"
  }
}

variable "mfa_required" {
  description = "Require MFA for all users"
  type        = bool
  default     = true
}

variable "password_policy" {
  description = "Password policy configuration"
  type = object({
    minimum_password_length        = number
    require_lowercase_characters   = bool
    require_numbers               = bool
    require_symbols               = bool
    require_uppercase_characters   = bool
    allow_users_to_change_password = bool
    max_password_age              = number
    password_reuse_prevention     = number
    hard_expiry                   = bool
  })
  default = {
    minimum_password_length        = 12
    require_lowercase_characters   = true
    require_numbers               = true
    require_symbols               = true
    require_uppercase_characters   = true
    allow_users_to_change_password = true
    max_password_age              = 90
    password_reuse_prevention     = 12
    hard_expiry                   = false
  }
}

variable "session_duration_hours" {
  description = "Maximum session duration for assumed roles in hours"
  type        = number
  default     = 8
  validation {
    condition     = var.session_duration_hours >= 1 && var.session_duration_hours <= 12
    error_message = "Session duration must be between 1 and 12 hours."
  }
}

variable "auto_user_management" {
  description = "Enable automatic user management features"
  type = object({
    auto_deactivate_unused_users = bool
    unused_user_threshold_days   = number
    auto_rotate_access_keys      = bool
    access_key_rotation_days     = number
  })
  default = {
    auto_deactivate_unused_users = true
    unused_user_threshold_days   = 90
    auto_rotate_access_keys      = true
    access_key_rotation_days     = 90
  }
}

variable "security_settings" {
  description = "Security settings for IAM"
  type = object({
    enable_cloudtrail_integration = bool
    enable_access_analyzer        = bool
    enable_credential_report      = bool
    notification_email           = string
  })
  default = {
    enable_cloudtrail_integration = true
    enable_access_analyzer        = true
    enable_credential_report      = true
    notification_email           = "hoseiitsandbox@gmail.com"
  }
}

variable "development_restrictions" {
  description = "Development environment restrictions"
  type = object({
    allowed_instance_types    = list(string)
    max_instances_per_user   = number
    auto_stop_after_hours    = number
    allowed_storage_types    = list(string)
    max_storage_gb_per_user  = number
  })
  default = {
    allowed_instance_types    = ["t3.nano", "t3.micro", "t3.small"]
    max_instances_per_user   = 2
    auto_stop_after_hours    = 8
    allowed_storage_types    = ["gp3", "gp2"]
    max_storage_gb_per_user  = 50
  }
}

variable "cost_control_settings" {
  description = "Cost control settings integrated with IAM"
  type = object({
    enforce_cost_tags          = bool
    required_cost_tags         = list(string)
    budget_alert_threshold     = number
    auto_stop_on_budget_breach = bool
  })
  default = {
    enforce_cost_tags          = true
    required_cost_tags         = ["Project", "Owner", "Environment", "CostCenter"]
    budget_alert_threshold     = 80
    auto_stop_on_budget_breach = false
  }
}

variable "lambda_execution_settings" {
  description = "Lambda execution role settings"
  type = object({
    max_execution_duration_minutes = number
    allowed_runtime_versions      = list(string)
    max_memory_mb                = number
    vpc_config_required          = bool
  })
  default = {
    max_execution_duration_minutes = 15
    allowed_runtime_versions      = ["python3.11", "python3.10", "nodejs18.x", "nodejs20.x"]
    max_memory_mb                = 1024
    vpc_config_required          = false
  }
}