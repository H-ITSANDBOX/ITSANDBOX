# ITSANDBOX Cost Management Module Variables

variable "organization_budget_limit" {
  description = "Monthly budget limit for the entire ITSANDBOX organization in USD"
  type        = string
  default     = "100"
}

variable "admin_email_addresses" {
  description = "List of admin email addresses for budget alerts"
  type        = list(string)
  default     = ["hoseiitsandbox@gmail.com"]
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for budget notifications (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "account_budgets" {
  description = "Budget configuration for each account"
  type = map(object({
    limit              = string
    notification_emails = list(string)
  }))
  default = {
    "shared-services" = {
      limit              = "20"
      notification_emails = []
    }
    "security-audit" = {
      limit              = "10"
      notification_emails = []
    }
    "network-hub" = {
      limit              = "5"
      notification_emails = []
    }
    "project-template" = {
      limit              = "15"
      notification_emails = []
    }
    "individual-sandbox" = {
      limit              = "5"
      notification_emails = []
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

variable "cost_anomaly_threshold" {
  description = "Cost anomaly detection threshold in USD"
  type        = number
  default     = 10
}

variable "enable_cost_optimization" {
  description = "Enable automated cost optimization features"
  type        = bool
  default     = true
}

variable "daily_report_enabled" {
  description = "Enable daily cost reports"
  type        = bool
  default     = true
}

variable "weekly_report_enabled" {
  description = "Enable weekly cost analysis reports"
  type        = bool
  default     = true
}

variable "auto_stop_resources" {
  description = "Enable automatic stopping of unused resources"
  type        = bool
  default     = false
}

variable "resource_optimization_rules" {
  description = "Rules for automatic resource optimization"
  type = object({
    stop_unused_ec2_instances   = bool
    delete_unused_snapshots     = bool
    optimize_s3_storage_class   = bool
    right_size_rds_instances    = bool
  })
  default = {
    stop_unused_ec2_instances   = false
    delete_unused_snapshots     = true
    optimize_s3_storage_class   = true
    right_size_rds_instances    = false
  }
}

variable "budget_action_thresholds" {
  description = "Budget thresholds for automated actions"
  type = object({
    warning_threshold    = number
    critical_threshold   = number
    emergency_threshold  = number
  })
  default = {
    warning_threshold    = 70  # 70%で警告
    critical_threshold   = 85  # 85%で重要アラート
    emergency_threshold  = 95  # 95%で緊急対応
  }
}