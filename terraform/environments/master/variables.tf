# Variables for ITSANDBOX Master Account

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "admin_email" {
  description = "Email address for admin notifications"
  type        = string
  default     = "hoseiitsandbox@gmail.com"
}

variable "organization_name" {
  description = "Name of the organization"
  type        = string
  default     = "ITSANDBOX"
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100
}

variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "ap-northeast-1"]
}

variable "allowed_instance_types" {
  description = "List of allowed EC2 instance types"
  type        = list(string)
  default     = ["t3.micro", "t3.small", "t3.medium"]
}

variable "allowed_rds_classes" {
  description = "List of allowed RDS instance classes"
  type        = list(string)
  default     = ["db.t3.micro", "db.t3.small"]
}

variable "cost_alert_thresholds" {
  description = "Cost alert thresholds as percentages"
  type        = list(number)
  default     = [50, 80, 90]
}

variable "tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Project     = "ITSANDBOX"
    Environment = "master"
    Owner       = "H-ITSANDBOX"
    CostCenter  = "ITSANDBOX-Master"
  }
}