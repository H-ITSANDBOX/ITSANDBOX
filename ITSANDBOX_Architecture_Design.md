# ITSANDBOX - AWS Multi-User Project Platform Architecture Design

## Executive Summary

ITSANDBOXは、複数のユーザーがプロジェクトを作成・管理できるAWSベースのプラットフォームです。初期は単一プロジェクトから開始し、スケーラブルな設計により複数プロジェクトへ拡張可能です。月額AWS費用を$100以内に抑える厳格なコスト管理機能を実装します。

## 1. Architecture Overview

### 1.1 Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        ITSANDBOX Platform                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │   Frontend   │     │   API Layer  │     │   Backend    │    │
│  │   (React)    │────▶│ (API Gateway)│────▶│  (Lambda)    │    │
│  │  CloudFront  │     │              │     │              │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│                                                    │             │
│  ┌──────────────┐     ┌──────────────┐           ▼             │
│  │    Auth      │     │   Storage    │     ┌──────────────┐    │
│  │  (Cognito)   │     │  (S3/DynamoDB)│     │  Database    │    │
│  │              │     │              │     │  (DynamoDB)  │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  Cost Management Layer                    │    │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────┐    │    │
│  │  │   Budget   │  │CloudWatch  │  │ Cost Explorer  │    │    │
│  │  │   Alerts   │  │   Alarms   │  │  Integration   │    │    │
│  │  └────────────┘  └────────────┘  └────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Multi-Project Architecture

```
Organization Root
├── Management Account (Billing & Security)
│   ├── AWS Organizations
│   ├── AWS Control Tower
│   └── Cost Management
│
├── Shared Services Account
│   ├── Central Logging
│   ├── Shared Resources
│   └── Network Hub
│
└── Project Accounts (Scalable)
    ├── Project 1 Account
    ├── Project 2 Account
    └── Project N Account
```

## 2. Core Services Implementation

### 2.1 User & Project Management

**DynamoDB Tables Structure:**

```
Users Table:
- userId (PK)
- email
- name
- role
- createdAt
- projectIds[]

Projects Table:
- projectId (PK)
- projectName
- ownerId
- members[]
- status
- awsAccountId
- monthlyBudget
- createdAt

ProjectResources Table:
- resourceId (PK)
- projectId (SK)
- resourceType
- resourceArn
- monthlyCost
- status
```

### 2.2 Authentication & Authorization

**AWS Cognito Configuration:**
- User Pools for authentication
- Identity Pools for AWS resource access
- Multi-factor authentication (MFA) optional
- OAuth 2.0 support for third-party integration

**IAM Role Structure:**
```
itsandbox-platform-admin-role
itsandbox-project-owner-role
itsandbox-project-member-role
itsandbox-project-viewer-role
```

## 3. Cost Management Strategy

### 3.1 Budget Controls

**AWS Budgets Configuration:**
```json
{
  "BudgetName": "ITSANDBOX-Monthly-Budget",
  "BudgetLimit": {
    "Amount": "100",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST",
  "CostFilters": {
    "TagKeyValue": ["Project:ITSANDBOX"]
  },
  "NotificationThresholds": [
    {
      "Threshold": 50,
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN"
    },
    {
      "Threshold": 80,
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN"
    },
    {
      "Threshold": 90,
      "NotificationType": "FORECASTED",
      "ComparisonOperator": "GREATER_THAN"
    }
  ]
}
```

### 3.2 Cost Optimization Strategies

1. **Serverless First Approach**
   - Lambda for compute (pay per request)
   - DynamoDB On-Demand for variable workloads
   - S3 Intelligent Tiering for storage

2. **Resource Limits**
   - Lambda concurrent execution limits
   - API Gateway rate limiting
   - DynamoDB read/write capacity limits

3. **Automated Cost Controls**
   - Lambda function to stop/terminate resources at budget threshold
   - Automated resource cleanup for unused resources
   - Project resource quotas

### 3.3 Monthly Cost Breakdown (Target)

```
Service               | Monthly Cost | Notes
---------------------|--------------|------------------------
Lambda               | $10-15       | 1M requests/month
API Gateway          | $5-10        | REST API calls
DynamoDB             | $10-15       | On-demand pricing
S3                   | $5-10        | 100GB storage
CloudFront           | $5-10        | CDN distribution
Cognito              | $0-5         | First 50K MAU free
CloudWatch           | $5-10        | Logs and metrics
Data Transfer        | $5-10        | Inter-region transfer
Buffer               | $20-30       | Unexpected costs
---------------------|--------------|------------------------
Total Target         | $65-100      | Within budget
```

## 4. Scalability Design

### 4.1 Project Isolation Strategies

**Option 1: Resource Tagging (Initial Phase)**
- All resources in single account
- Project isolation via tagging
- Cost allocation by tags
- Suitable for 1-10 projects

**Option 2: Multi-Account (Growth Phase)**
- Separate AWS account per project
- AWS Organizations for management
- Service Control Policies (SCPs)
- Suitable for 10+ projects

### 4.2 Auto-Scaling Configuration

```yaml
Lambda Functions:
  ReservedConcurrency: 100
  AutoScaling:
    MinConcurrency: 0
    MaxConcurrency: 1000
    TargetUtilization: 0.7

DynamoDB Tables:
  BillingMode: ON_DEMAND
  PointInTimeRecovery: true
  GlobalTables: false  # Enable for multi-region

API Gateway:
  ThrottleSettings:
    RateLimit: 1000
    BurstLimit: 2000
  UsagePlans:
    - Name: Basic
      Throttle:
        RateLimit: 100
        BurstLimit: 200
    - Name: Premium
      Throttle:
        RateLimit: 1000
        BurstLimit: 2000
```

## 5. Security Architecture

### 5.1 Network Security

```
VPC Configuration:
├── Public Subnets (NAT Gateway)
├── Private Subnets (Lambda, RDS if needed)
└── Database Subnets (Isolated)

Security Groups:
- sg-frontend: CloudFront only
- sg-api: HTTPS only (443)
- sg-lambda: Outbound only
- sg-database: Lambda access only
```

### 5.2 Data Security

- **Encryption at Rest**: All S3, DynamoDB with AWS KMS
- **Encryption in Transit**: TLS 1.2+ enforced
- **Secrets Management**: AWS Secrets Manager
- **Audit Logging**: CloudTrail for all API calls

### 5.3 Compliance & Governance

```
AWS Config Rules:
- required-tags
- s3-bucket-public-read-prohibited
- dynamodb-encryption-check
- lambda-function-public-access-prohibited
- api-gateway-execution-logging-enabled
```

## 6. Monitoring & Alerting

### 6.1 CloudWatch Dashboards

**Main Dashboard Widgets:**
1. Total Monthly Cost (Current vs Budget)
2. Cost by Service Breakdown
3. Cost by Project
4. API Request Count
5. Lambda Invocation Count
6. Error Rate
7. User Activity

### 6.2 Alarms Configuration

```json
{
  "CostAlarms": [
    {
      "Name": "DailyCostExceeded",
      "Threshold": 3.33,
      "Period": "DAILY"
    },
    {
      "Name": "ProjectCostAnomaly",
      "Threshold": "20% increase",
      "Period": "HOURLY"
    }
  ],
  "PerformanceAlarms": [
    {
      "Name": "HighErrorRate",
      "Metric": "4XXError",
      "Threshold": 10,
      "Period": 300
    },
    {
      "Name": "LambdaThrottling",
      "Metric": "Throttles",
      "Threshold": 5,
      "Period": 300
    }
  ]
}
```

## 7. Development Workflow

### 7.1 CI/CD Pipeline

```
GitHub Repository
    │
    ├── main branch ──► Production Environment
    ├── develop branch ──► Staging Environment
    └── feature/* branches ──► Development Environment

AWS CodePipeline:
1. Source (GitHub)
2. Build (CodeBuild)
3. Test (Lambda tests)
4. Deploy (CloudFormation/CDK)
5. Validation (Smoke tests)
```

### 7.2 Infrastructure as Code

**Terraform Directory Structure:**
```
terraform/
├── modules/
│   ├── networking/
│   ├── compute/
│   ├── storage/
│   ├── security/
│   └── monitoring/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
├── global/
│   ├── iam/
│   └── organizations/
└── main.tf
```

## 8. Project Management Features

### 8.1 User Interface Components

1. **Dashboard**
   - Project overview
   - Cost tracking
   - Resource utilization
   - Team members

2. **Project Creation Wizard**
   - Project name and description
   - Budget allocation
   - Team member invitation
   - Resource templates

3. **Cost Management View**
   - Real-time cost tracking
   - Budget vs actual
   - Cost forecasting
   - Resource optimization suggestions

### 8.2 API Endpoints

```
/api/v1/projects
  POST   - Create new project
  GET    - List user's projects
  
/api/v1/projects/{projectId}
  GET    - Get project details
  PUT    - Update project
  DELETE - Delete project
  
/api/v1/projects/{projectId}/members
  POST   - Add member
  DELETE - Remove member
  
/api/v1/projects/{projectId}/costs
  GET    - Get cost breakdown
  
/api/v1/projects/{projectId}/resources
  GET    - List project resources
  POST   - Create resource
  DELETE - Delete resource
```

## 9. Implementation Phases

### Phase 1: MVP (Month 1-2)
- Basic authentication (Cognito)
- Single project support
- Cost tracking dashboard
- Basic resource management

### Phase 2: Multi-Project (Month 3-4)
- Multiple project support
- Advanced cost allocation
- Team collaboration features
- Resource templates

### Phase 3: Enterprise Features (Month 5-6)
- Multi-account support
- Advanced security features
- Compliance reporting
- API marketplace

## 10. Cost Control Automation

### 10.1 Lambda Function for Cost Control

```python
import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    ce = boto3.client('ce')
    budgets = boto3.client('budgets')
    
    # Get current month costs
    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': datetime.now().strftime('%Y-%m-01'),
            'End': datetime.now().strftime('%Y-%m-%d')
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost']
    )
    
    total_cost = sum(float(day['Total']['UnblendedCost']['Amount']) 
                     for day in response['ResultsByTime'])
    
    # Check if approaching budget limit
    if total_cost > 80:  # $80 threshold
        # Implement cost reduction actions
        stop_non_essential_resources()
        send_alert_notification()
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'currentCost': total_cost,
            'budgetRemaining': 100 - total_cost
        })
    }
```

## 11. Disaster Recovery

### 11.1 Backup Strategy
- DynamoDB: Point-in-time recovery enabled
- S3: Cross-region replication for critical data
- Lambda: Function versioning and aliases
- Configuration: All stored in Git

### 11.2 RTO/RPO Targets
- Recovery Time Objective (RTO): 1 hour
- Recovery Point Objective (RPO): 15 minutes

## 12. Success Metrics

1. **Cost Efficiency**
   - Monthly AWS cost < $100
   - Cost per project < $10
   - Resource utilization > 70%

2. **Performance**
   - API response time < 200ms
   - Dashboard load time < 2s
   - 99.9% uptime

3. **User Adoption**
   - User growth rate
   - Project creation rate
   - Active user percentage

## Next Steps

1. Review and approve architecture design
2. Set up AWS Organization structure
3. Create Terraform modules
4. Implement MVP features
5. Deploy to development environment
6. Conduct cost analysis and optimization

---

*Document Version: 1.0*  
*Last Updated: 2024-01-08*  
*Author: ITSANDBOX Architecture Team*