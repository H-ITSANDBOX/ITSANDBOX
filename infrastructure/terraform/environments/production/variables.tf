# ITSANDBOX Ultra-Low-Cost Infrastructure Variables

# ====================
# Domain Configuration
# ====================

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
  default     = "hosei-itsandbox.com"
}

variable "enable_custom_domain" {
  description = "Whether to enable custom domain with Route 53 and SSL"
  type        = bool
  default     = true
}

variable "enable_lambda_backend" {
  description = "Whether to enable Lambda backend (disabled for ultra-low-cost)"
  type        = bool
  default     = false
}

# ====================
# Cost Management
# ====================

variable "organization_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "5"
}

variable "admin_emails" {
  description = "List of admin email addresses for budget alerts"
  type        = list(string)
  default     = ["hoseiitsandbox@gmail.com"]
}

# ====================
# Environment Settings
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
  description = "Enable detailed CloudWatch monitoring (costs extra)"
  type        = bool
  default     = false
}

variable "enable_backup" {
  description = "Enable backup services (disabled for cost optimization)"
  type        = bool
  default     = false
}

variable "retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 7
}

# ====================
# Security Settings
# ====================

variable "enable_waf" {
  description = "Enable AWS WAF (disabled for cost optimization)"
  type        = bool
  default     = false
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced (disabled for cost optimization)"
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty (disabled for cost optimization)"
  type        = bool
  default     = false
}

variable "enable_config" {
  description = "Enable AWS Config (disabled for cost optimization)"
  type        = bool
  default     = false
}

# ====================
# Performance Settings
# ====================

variable "performance_settings" {
  description = "Performance and cost optimization settings"
  type = object({
    cloudfront_price_class = string
    s3_intelligent_tiering = bool
  })
  default = {
    cloudfront_price_class = "PriceClass_100" # US, Canada, Europe
    s3_intelligent_tiering = false            # Disabled for cost
  }
}

# ====================
# Development Features
# ====================

variable "development_features" {
  description = "Development and debugging features"
  type = object({
    enable_debug_logging     = bool
    enable_x_ray_tracing     = bool
    enable_local_development = bool
    debug_retention_days     = number
  })
  default = {
    enable_debug_logging     = false
    enable_x_ray_tracing     = false
    enable_local_development = false
    debug_retention_days     = 1
  }
}

# ====================
# Compliance Settings
# ====================

variable "compliance_settings" {
  description = "Compliance and auditing settings"
  type = object({
    enable_cloudtrail_data_events  = bool
    enable_vpc_flow_logs           = bool
    enable_access_logging          = bool
    encryption_at_rest_required    = bool
    encryption_in_transit_required = bool
  })
  default = {
    enable_cloudtrail_data_events  = false
    enable_vpc_flow_logs           = false
    enable_access_logging          = false
    encryption_at_rest_required    = true
    encryption_in_transit_required = true
  }
}

# ====================
# Disaster Recovery
# ====================

variable "disaster_recovery" {
  description = "Disaster recovery settings"
  type = object({
    enable_cross_region_backup = bool
    backup_retention_days      = number
    rto_hours                  = number
    rpo_hours                  = number
    secondary_region           = string
  })
  default = {
    enable_cross_region_backup = false
    backup_retention_days      = 7
    rto_hours                  = 24
    rpo_hours                  = 48
    secondary_region           = "us-west-2"
  }
}

# ====================
# Tagging
# ====================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    Project      = "ITSANDBOX"
    Department   = "経営システム工学科"
    University   = "法政大学"
    Contact      = "hoseiitsandbox@gmail.com"
    Purpose      = "Ultra-Low-Cost IT Innovation"
    Architecture = "S3-CloudFront-Route53"
    CostTarget   = "Under-5-USD-Monthly"
  }
}

variable "cost_allocation_tags" {
  description = "List of tag keys for cost allocation"
  type        = list(string)
  default = [
    "Project",
    "Environment",
    "Architecture",
    "CostTarget"
  ]
}