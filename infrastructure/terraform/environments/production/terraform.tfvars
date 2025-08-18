# ITSANDBOX Ultra-Low-Cost AWS Deployment Configuration
# 月額$5以下のS3 + CloudFront + Route 53構成

# ====================
# Domain Configuration
# ====================
domain_name           = "hosei-itsandbox.com"
enable_custom_domain  = true
enable_lambda_backend = false

# ====================
# Cost Management (Ultra-Low-Cost Settings)
# ====================
organization_budget_limit = "5" # $5/month budget

# ====================
# Ultra-Low-Cost S3 + CloudFront Settings
# ====================
environment = "production"

# Performance settings optimized for cost
performance_settings = {
  cloudfront_price_class = "PriceClass_100" # US, Canada, Europe only
  s3_intelligent_tiering = false            # Disable to reduce costs
}

# Minimal monitoring to stay within free tier
enable_detailed_monitoring = false
enable_backup              = false
retention_days             = 7

# Security settings (minimal cost)
enable_waf       = false
enable_shield    = false
enable_guardduty = false
enable_config    = false

# Development features (disabled for cost)
development_features = {
  enable_debug_logging     = false
  enable_x_ray_tracing     = false
  enable_local_development = false
  debug_retention_days     = 1
}

# Compliance settings (minimal)
compliance_settings = {
  enable_cloudtrail_data_events  = false
  enable_vpc_flow_logs           = false
  enable_access_logging          = false
  encryption_at_rest_required    = true
  encryption_in_transit_required = true
}

# Disaster recovery (disabled for cost)
disaster_recovery = {
  enable_cross_region_backup = false
  backup_retention_days      = 7
  rto_hours                  = 24
  rpo_hours                  = 48
  secondary_region           = "us-west-2"
}

# ====================
# Team Configuration (Minimal)
# ====================
admin_emails = [
  "hoseiitsandbox@gmail.com"
]

# ====================
# Cost Allocation Tags
# ====================
additional_tags = {
  Project      = "ITSANDBOX"
  Department   = "経営システム工学科"
  University   = "法政大学"
  Contact      = "hoseiitsandbox@gmail.com"
  Purpose      = "Ultra-Low-Cost IT Innovation"
  Architecture = "S3-CloudFront-Route53"
  CostTarget   = "Under-5-USD-Monthly"
}

cost_allocation_tags = [
  "Project",
  "Environment",
  "Architecture",
  "CostTarget"
]