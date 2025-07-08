# ITSANDBOX Production Environment Variables

# ====================
# AWS Configuration
# ====================

variable "aws_region" {
  description = "Primary AWS region for ITSANDBOX resources"
  type        = string
  default     = "us-east-1"
}

variable "allowed_regions" {
  description = "List of allowed AWS regions for resource deployment"
  type        = list(string)
  default     = ["us-east-1", "ap-northeast-1"]
}

# ====================
# Organization Configuration
# ====================

variable "organization_id" {
  description = "AWS Organization ID"
  type        = string
}

variable "master_account_id" {
  description = "AWS master account ID"
  type        = string
}

variable "trusted_account_ids" {
  description = "List of trusted AWS account IDs for cross-account access"
  type        = list(string)
  default     = []
}

variable "project_account_ids" {
  description = "List of project-specific AWS account IDs"
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID for cross-account role assumption security"
  type        = string
  sensitive   = true
}

# ====================
# Cost Management
# ====================

variable "organization_budget_limit" {
  description = "Monthly budget limit for the entire ITSANDBOX organization in USD"
  type        = string
  default     = "100"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for budget and system notifications"
  type        = string
  default     = ""
  sensitive   = true
}

# ====================
# Notification Configuration
# ====================

variable "admin_emails" {
  description = "List of administrator email addresses for critical notifications"
  type        = list(string)
  default     = ["hoseiitsandbox@gmail.com"]
}

variable "security_notification_email" {
  description = "Email address for security-related notifications"
  type        = string
  default     = "hoseiitsandbox@gmail.com"
}

# ====================
# Domain and SSL Configuration
# ====================

variable "domain_name" {
  description = "Primary domain name for ITSANDBOX services"
  type        = string
  default     = "itsandbox.hosei.ac.jp"
}

variable "create_hosted_zone" {
  description = "Create Route 53 hosted zone for the domain"
  type        = bool
  default     = false
}

variable "create_ssl_certificate" {
  description = "Create ACM SSL certificate for the domain"
  type        = bool
  default     = false
}

# ====================
# Project Team Configuration
# ====================

# Website Project Team
variable "website_project_leads" {
  description = "List of IAM user ARNs for website project leads"
  type        = list(string)
  default     = []
}

variable "website_developers" {
  description = "List of IAM user ARNs for website developers"
  type        = list(string)
  default     = []
}

variable "website_viewers" {
  description = "List of IAM user ARNs for website viewers"
  type        = list(string)
  default     = []
}

# API Project Team
variable "api_project_leads" {
  description = "List of IAM user ARNs for API project leads"
  type        = list(string)
  default     = []
}

variable "api_developers" {
  description = "List of IAM user ARNs for API developers"
  type        = list(string)
  default     = []
}

variable "api_viewers" {
  description = "List of IAM user ARNs for API viewers"
  type        = list(string)
  default     = []
}

# Infrastructure Project Team
variable "infra_project_leads" {
  description = "List of IAM user ARNs for infrastructure project leads"
  type        = list(string)
  default     = []
}

variable "infra_developers" {
  description = "List of IAM user ARNs for infrastructure developers"
  type        = list(string)
  default     = []
}

variable "infra_viewers" {
  description = "List of IAM user ARNs for infrastructure viewers"
  type        = list(string)
  default     = []
}

# Sandbox Project Team
variable "sandbox_project_leads" {
  description = "List of IAM user ARNs for sandbox project leads"
  type        = list(string)
  default     = []
}

variable "sandbox_developers" {
  description = "List of IAM user ARNs for sandbox developers"
  type        = list(string)
  default     = []
}

variable "sandbox_viewers" {
  description = "List of IAM user ARNs for sandbox viewers"
  type        = list(string)
  default     = []
}

# ====================
# Environment Configuration
# ====================

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for resources"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backup for critical resources"
  type        = bool
  default     = true
}

variable "retention_days" {
  description = "Default retention period for logs and backups in days"
  type        = number
  default     = 90
}

# ====================
# Security Configuration
# ====================

variable "enable_waf" {
  description = "Enable AWS WAF for web applications"
  type        = bool
  default     = true
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced for DDoS protection"
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

# ====================
# Development Configuration
# ====================

variable "development_features" {
  description = "Development and debugging features configuration"
  type = object({
    enable_debug_logging     = bool
    enable_x_ray_tracing    = bool
    enable_local_development = bool
    debug_retention_days    = number
  })
  default = {
    enable_debug_logging     = false
    enable_x_ray_tracing    = true
    enable_local_development = false
    debug_retention_days    = 7
  }
}

# ====================
# Performance Configuration
# ====================

variable "performance_settings" {
  description = "Performance optimization settings"
  type = object({
    cloudfront_price_class         = string
    lambda_reserved_concurrency    = number
    dynamodb_billing_mode         = string
    s3_intelligent_tiering        = bool
  })
  default = {
    cloudfront_price_class         = "PriceClass_100"  # US, Canada, Europe
    lambda_reserved_concurrency    = 10
    dynamodb_billing_mode         = "PAY_PER_REQUEST"
    s3_intelligent_tiering        = true
  }
}

# ====================
# Compliance Configuration
# ====================

variable "compliance_settings" {
  description = "Compliance and governance settings"
  type = object({
    enable_cloudtrail_data_events = bool
    enable_vpc_flow_logs         = bool
    enable_access_logging        = bool
    encryption_at_rest_required  = bool
    encryption_in_transit_required = bool
  })
  default = {
    enable_cloudtrail_data_events = true
    enable_vpc_flow_logs         = true
    enable_access_logging        = true
    encryption_at_rest_required  = true
    encryption_in_transit_required = true
  }
}

# ====================
# Disaster Recovery Configuration
# ====================

variable "disaster_recovery" {
  description = "Disaster recovery configuration"
  type = object({
    enable_cross_region_backup = bool
    backup_retention_days     = number
    rto_hours                = number
    rpo_hours                = number
    secondary_region         = string
  })
  default = {
    enable_cross_region_backup = false
    backup_retention_days     = 30
    rto_hours                = 4
    rpo_hours                = 24
    secondary_region         = "us-west-2"
  }
}

# ====================
# Tagging Strategy
# ====================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cost_allocation_tags" {
  description = "Tags used for cost allocation and billing"
  type        = list(string)
  default     = ["Project", "Environment", "Owner", "CostCenter", "Team"]
}