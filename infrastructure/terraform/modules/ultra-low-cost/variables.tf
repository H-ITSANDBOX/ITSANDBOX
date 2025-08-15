# Variables for Ultra-Low-Cost ITSANDBOX Infrastructure

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "itsandbox"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "GitHub repository name"
  type        = string
  default     = "itsandbox"
}

variable "github_username" {
  description = "GitHub username or organization"
  type        = string
  default     = "hosei-itsandbox"
}

variable "admin_emails" {
  description = "List of admin email addresses for notifications"
  type        = list(string)
  default     = ["hoseiitsandbox@gmail.com"]
}

variable "domain_name" {
  description = "Custom domain name (optional, use GitHub Pages subdomain for $0 cost)"
  type        = string
  default     = null
}

variable "enable_custom_domain" {
  description = "Enable custom domain (adds cost for Route 53)"
  type        = bool
  default     = false
}

variable "enable_lambda_backend" {
  description = "Enable minimal Lambda backend (adds ~$1-2/month)"
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for GitHub Actions"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for GitHub Actions"
  type        = string
  sensitive   = true
}

variable "notification_webhook_url" {
  description = "Webhook URL for notifications (Discord/Slack)"
  type        = string
  default     = ""
}

variable "lambda_zip_path" {
  description = "Path to Lambda deployment package"
  type        = string
  default     = "../../../backend/minimal-lambda.zip"
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "ITSANDBOX"
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostTarget  = "Under5USD"
    Architecture = "Ultra-Low-Cost"
  }
}

# Cost optimization variables
variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 5.0
}

variable "budget_alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
  default     = 80
}

variable "s3_lifecycle_days_to_ia" {
  description = "Days before transitioning to IA storage class"
  type        = number
  default     = 30
}

variable "s3_lifecycle_days_to_glacier" {
  description = "Days before transitioning to Glacier"
  type        = number
  default     = 90
}

variable "s3_lifecycle_days_to_deep_archive" {
  description = "Days before transitioning to Deep Archive"
  type        = number
  default     = 365
}