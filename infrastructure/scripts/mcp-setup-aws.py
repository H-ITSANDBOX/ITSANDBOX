#!/usr/bin/env python3
"""
ITSANDBOX AWS セットアップスクリプト (MCP対応)
MCPサーバーの情報を活用してAWS環境を構築
"""

import json
import boto3
import logging
import argparse
import time
import os
import sys
from typing import Dict, List, Any, Optional
from botocore.exceptions import ClientError, BotoCoreError

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ITSANDBOXAWSSetup:
    """ITSANDBOX AWS環境セットアップクラス"""
    
    def __init__(self, profile: Optional[str] = None, region: str = 'us-east-1'):
        self.region = region
        
        # AWSセッション初期化
        try:
            if profile:
                session = boto3.Session(profile_name=profile)
            else:
                session = boto3.Session()
            
            # クライアント初期化
            self.organizations = session.client('organizations', region_name=region)
            self.iam = session.client('iam', region_name=region)
            self.sts = session.client('sts', region_name=region)
            self.budgets = session.client('budgets', region_name=region)
            self.sns = session.client('sns', region_name=region)
            self.s3 = session.client('s3', region_name=region)
            self.dynamodb = session.client('dynamodb', region_name=region)
            
            # 現在のアカウント情報取得
            self.current_account = self.sts.get_caller_identity()
            logger.info(f"✅ AWS設定完了 - アカウント: {self.current_account['Account']}")
            
        except Exception as e:
            logger.error(f"❌ AWS設定エラー: {str(e)}")
            raise
    
    def check_prerequisites(self) -> bool:
        """前提条件チェック"""
        logger.info("🔍 前提条件をチェック中...")
        
        try:
            # 権限チェック
            self.sts.get_caller_identity()
            logger.info("✅ AWS認証情報確認済み")
            
            # Organizations権限チェック
            try:
                self.organizations.describe_organization()
                logger.info("✅ Organizations権限確認済み")
            except ClientError as e:
                if e.response['Error']['Code'] == 'AWSOrganizationsNotInUseException':
                    logger.info("ℹ️  Organization未作成（作成予定）")
                else:
                    logger.warning(f"⚠️  Organizations権限制限: {e}")
            
            # IAM権限チェック
            try:
                self.iam.list_users(MaxItems=1)
                logger.info("✅ IAM権限確認済み")
            except ClientError as e:
                logger.error(f"❌ IAM権限不足: {e}")
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"❌ 前提条件チェック失敗: {str(e)}")
            return False
    
    def create_organization(self) -> Optional[str]:
        """AWS Organization作成"""
        logger.info("🏢 AWS Organization作成中...")
        
        try:
            # 既存Organization確認
            try:
                org = self.organizations.describe_organization()
                org_id = org['Organization']['Id']
                logger.info(f"✅ 既存Organization発見: {org_id}")
                return org_id
            except ClientError as e:
                if e.response['Error']['Code'] != 'AWSOrganizationsNotInUseException':
                    raise
            
            # 新規Organization作成
            org_response = self.organizations.create_organization(FeatureSet='ALL')
            org_id = org_response['Organization']['Id']
            
            logger.info(f"✅ Organization作成完了: {org_id}")
            
            # Organization情報保存
            with open('organization-info.json', 'w') as f:
                json.dump(org_response, f, indent=2, default=str)
            
            return org_id
            
        except Exception as e:
            logger.error(f"❌ Organization作成失敗: {str(e)}")
            return None
    
    def create_organizational_units(self) -> Dict[str, str]:
        """Organizational Units作成"""
        logger.info("📁 Organizational Units作成中...")
        
        ous = {
            'Core': 'Core accounts for shared services',
            'Projects': 'Project-specific development accounts',
            'Sandbox': 'Individual sandbox environments'
        }
        
        created_ous = {}
        
        try:
            # Root OU取得
            roots = self.organizations.list_roots()
            root_id = roots['Roots'][0]['Id']
            
            for ou_name, description in ous.items():
                try:
                    # 既存OU確認
                    existing_ous = self.organizations.list_organizational_units_for_parent(
                        ParentId=root_id
                    )
                    
                    existing_ou = None
                    for ou in existing_ous['OrganizationalUnits']:
                        if ou['Name'] == ou_name:
                            existing_ou = ou
                            break
                    
                    if existing_ou:
                        created_ous[ou_name] = existing_ou['Id']
                        logger.info(f"✅ 既存OU発見: {ou_name} ({existing_ou['Id']})")
                    else:
                        # 新規OU作成
                        ou_response = self.organizations.create_organizational_unit(
                            ParentId=root_id,
                            Name=ou_name
                        )
                        created_ous[ou_name] = ou_response['OrganizationalUnit']['Id']
                        logger.info(f"✅ OU作成完了: {ou_name} ({ou_response['OrganizationalUnit']['Id']})")
                
                except Exception as e:
                    logger.error(f"❌ OU作成失敗 {ou_name}: {str(e)}")
            
            return created_ous
            
        except Exception as e:
            logger.error(f"❌ OU作成処理失敗: {str(e)}")
            return {}
    
    def setup_iam_policies(self) -> Dict[str, str]:
        """IAMポリシー作成"""
        logger.info("🔐 IAMポリシー作成中...")
        
        policies = {}
        
        # 基本ポリシー定義
        policy_definitions = {
            'ITSANDBOXDeveloperPolicy': {
                'description': 'ITSANDBOX developer permissions',
                'document': {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Action": [
                                "lambda:*",
                                "s3:GetObject",
                                "s3:PutObject",
                                "s3:ListBucket",
                                "dynamodb:GetItem",
                                "dynamodb:PutItem",
                                "dynamodb:UpdateItem",
                                "dynamodb:Query",
                                "cloudwatch:GetMetricStatistics",
                                "logs:CreateLogGroup",
                                "logs:CreateLogStream",
                                "logs:PutLogEvents"
                            ],
                            "Resource": "*",
                            "Condition": {
                                "StringEquals": {
                                    "aws:RequestedRegion": ["us-east-1", "ap-northeast-1"]
                                }
                            }
                        }
                    ]
                }
            },
            'ITSANDBOXPermissionsBoundary': {
                'description': 'ITSANDBOX permissions boundary',
                'document': {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Action": [
                                "lambda:*",
                                "s3:*",
                                "dynamodb:*",
                                "cloudwatch:*",
                                "logs:*"
                            ],
                            "Resource": "*"
                        },
                        {
                            "Effect": "Deny",
                            "Action": [
                                "ec2:*",
                                "rds:*",
                                "organizations:*"
                            ],
                            "Resource": "*"
                        }
                    ]
                }
            }
        }
        
        for policy_name, policy_config in policy_definitions.items():
            try:
                # 既存ポリシー確認
                try:
                    policy_arn = f"arn:aws:iam::{self.current_account['Account']}:policy/itsandbox/{policy_name}"
                    self.iam.get_policy(PolicyArn=policy_arn)
                    policies[policy_name] = policy_arn
                    logger.info(f"✅ 既存ポリシー発見: {policy_name}")
                    continue
                except ClientError as e:
                    if e.response['Error']['Code'] != 'NoSuchEntity':
                        raise
                
                # 新規ポリシー作成
                response = self.iam.create_policy(
                    PolicyName=policy_name,
                    Path='/itsandbox/',
                    Description=policy_config['description'],
                    PolicyDocument=json.dumps(policy_config['document'])
                )
                
                policies[policy_name] = response['Policy']['Arn']
                logger.info(f"✅ ポリシー作成完了: {policy_name}")
                
            except Exception as e:
                logger.error(f"❌ ポリシー作成失敗 {policy_name}: {str(e)}")
        
        return policies
    
    def setup_iam_roles(self, policies: Dict[str, str]) -> Dict[str, str]:
        """IAMロール作成"""
        logger.info("👥 IAMロール作成中...")
        
        roles = {}
        
        # 基本ロール定義
        role_definitions = {
            'ITSANDBOXDeveloperRole': {
                'description': 'ITSANDBOX developer role',
                'assume_role_policy': {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {
                                "AWS": f"arn:aws:iam::{self.current_account['Account']}:root"
                            },
                            "Action": "sts:AssumeRole",
                            "Condition": {
                                "StringEquals": {
                                    "sts:ExternalId": "ITSANDBOX-2024-Dev"
                                }
                            }
                        }
                    ]
                },
                'attached_policies': ['ITSANDBOXDeveloperPolicy'],
                'permissions_boundary': 'ITSANDBOXPermissionsBoundary'
            }
        }
        
        for role_name, role_config in role_definitions.items():
            try:
                # 既存ロール確認
                try:
                    role_response = self.iam.get_role(RoleName=role_name)
                    roles[role_name] = role_response['Role']['Arn']
                    logger.info(f"✅ 既存ロール発見: {role_name}")
                    continue
                except ClientError as e:
                    if e.response['Error']['Code'] != 'NoSuchEntity':
                        raise
                
                # 新規ロール作成
                create_params = {
                    'RoleName': role_name,
                    'Path': '/itsandbox/',
                    'AssumeRolePolicyDocument': json.dumps(role_config['assume_role_policy']),
                    'Description': role_config['description']
                }
                
                # Permissions Boundary設定
                if role_config.get('permissions_boundary') and role_config['permissions_boundary'] in policies:
                    create_params['PermissionsBoundary'] = policies[role_config['permissions_boundary']]
                
                role_response = self.iam.create_role(**create_params)
                roles[role_name] = role_response['Role']['Arn']
                
                # ポリシーアタッチ
                for policy_name in role_config.get('attached_policies', []):
                    if policy_name in policies:
                        self.iam.attach_role_policy(
                            RoleName=role_name,
                            PolicyArn=policies[policy_name]
                        )
                
                logger.info(f"✅ ロール作成完了: {role_name}")
                
            except Exception as e:
                logger.error(f"❌ ロール作成失敗 {role_name}: {str(e)}")
        
        return roles
    
    def setup_cost_management(self) -> bool:
        """コスト管理設定"""
        logger.info("💰 コスト管理設定中...")
        
        try:
            # 予算作成
            budget_name = 'ITSANDBOX-Monthly-Budget'
            
            try:
                # 既存予算確認
                self.budgets.describe_budget(
                    AccountId=self.current_account['Account'],
                    BudgetName=budget_name
                )
                logger.info(f"✅ 既存予算発見: {budget_name}")
                return True
                
            except ClientError as e:
                if e.response['Error']['Code'] != 'NotFoundException':
                    raise
            
            # 新規予算作成
            budget = {
                'BudgetName': budget_name,
                'BudgetType': 'COST',
                'TimeUnit': 'MONTHLY',
                'BudgetLimit': {
                    'Amount': '100.0',
                    'Unit': 'USD'
                },
                'CostFilters': {},
                'TimePeriod': {
                    'Start': '2024-01-01',
                    'End': '2087-06-15'
                }
            }
            
            # 通知設定
            notification = {
                'NotificationType': 'ACTUAL',
                'ComparisonOperator': 'GREATER_THAN',
                'Threshold': 80.0,
                'ThresholdType': 'PERCENTAGE'
            }
            
            subscriber = {
                'SubscriptionType': 'EMAIL',
                'Address': 'hoseiitsandbox@gmail.com'
            }
            
            self.budgets.create_budget(
                AccountId=self.current_account['Account'],
                Budget=budget,
                NotificationsWithSubscribers=[
                    {
                        'Notification': notification,
                        'Subscribers': [subscriber]
                    }
                ]
            )
            
            logger.info(f"✅ 予算作成完了: {budget_name}")
            return True
            
        except Exception as e:
            logger.error(f"❌ コスト管理設定失敗: {str(e)}")
            return False
    
    def setup_shared_resources(self) -> Dict[str, str]:
        """共有リソース作成"""
        logger.info("🗂️ 共有リソース作成中...")
        
        resources = {}
        
        try:
            # S3バケット作成
            bucket_name = f"itsandbox-shared-{self.current_account['Account']}-{int(time.time())}"
            
            try:
                if self.region == 'us-east-1':
                    self.s3.create_bucket(Bucket=bucket_name)
                else:
                    self.s3.create_bucket(
                        Bucket=bucket_name,
                        CreateBucketConfiguration={'LocationConstraint': self.region}
                    )
                
                # バケット暗号化設定
                self.s3.put_bucket_encryption(
                    Bucket=bucket_name,
                    ServerSideEncryptionConfiguration={
                        'Rules': [
                            {
                                'ApplyServerSideEncryptionByDefault': {
                                    'SSEAlgorithm': 'AES256'
                                }
                            }
                        ]
                    }
                )
                
                # パブリックアクセスブロック
                self.s3.put_public_access_block(
                    Bucket=bucket_name,
                    PublicAccessBlockConfiguration={
                        'BlockPublicAcls': True,
                        'IgnorePublicAcls': True,
                        'BlockPublicPolicy': True,
                        'RestrictPublicBuckets': True
                    }
                )
                
                resources['s3_bucket'] = bucket_name
                logger.info(f"✅ S3バケット作成完了: {bucket_name}")
                
            except Exception as e:
                logger.error(f"❌ S3バケット作成失敗: {str(e)}")
            
            # DynamoDBテーブル作成
            table_name = 'itsandbox-terraform-locks'
            
            try:
                self.dynamodb.create_table(
                    TableName=table_name,
                    KeySchema=[
                        {
                            'AttributeName': 'LockID',
                            'KeyType': 'HASH'
                        }
                    ],
                    AttributeDefinitions=[
                        {
                            'AttributeName': 'LockID',
                            'AttributeType': 'S'
                        }
                    ],
                    BillingMode='PAY_PER_REQUEST',
                    Tags=[
                        {
                            'Key': 'Project',
                            'Value': 'ITSANDBOX'
                        },
                        {
                            'Key': 'Purpose',
                            'Value': 'TerraformLocking'
                        }
                    ]
                )
                
                resources['dynamodb_table'] = table_name
                logger.info(f"✅ DynamoDBテーブル作成完了: {table_name}")
                
            except ClientError as e:
                if e.response['Error']['Code'] == 'ResourceInUseException':
                    resources['dynamodb_table'] = table_name
                    logger.info(f"✅ 既存DynamoDBテーブル発見: {table_name}")
                else:
                    logger.error(f"❌ DynamoDBテーブル作成失敗: {str(e)}")
            
        except Exception as e:
            logger.error(f"❌ 共有リソース作成失敗: {str(e)}")
        
        return resources
    
    def generate_terraform_backend_config(self, resources: Dict[str, str]) -> bool:
        """Terraformバックエンド設定生成"""
        logger.info("📝 Terraformバックエンド設定生成中...")
        
        try:
            if 's3_bucket' not in resources or 'dynamodb_table' not in resources:
                logger.warning("⚠️ S3バケットまたはDynamoDBテーブルが不足")
                return False
            
            backend_config = f"""# ITSANDBOX Terraform Backend Configuration
# 自動生成されました: {time.strftime('%Y-%m-%d %H:%M:%S')}

terraform {{
  backend "s3" {{
    bucket         = "{resources['s3_bucket']}"
    key            = "itsandbox/terraform.tfstate"
    region         = "{self.region}"
    encrypt        = true
    dynamodb_table = "{resources['dynamodb_table']}"
  }}
}}
"""
            
            with open('terraform-backend.tf', 'w') as f:
                f.write(backend_config)
            
            # terraform.tfvars生成
            tfvars_content = f"""# ITSANDBOX Terraform Variables
# 自動生成されました: {time.strftime('%Y-%m-%d %H:%M:%S')}

# AWS Configuration
aws_region = "{self.region}"
master_account_id = "{self.current_account['Account']}"

# Organization Configuration
organization_id = "UPDATE_AFTER_TERRAFORM_APPLY"
external_id = "ITSANDBOX-2024-SecureExternalId-{int(time.time())}"

# Cost Management
organization_budget_limit = "100"

# Admin Configuration
admin_emails = ["hoseiitsandbox@gmail.com"]
security_notification_email = "hoseiitsandbox@gmail.com"

# Project Teams (更新してください)
website_project_leads = []
website_developers = []
api_project_leads = []
api_developers = []
infra_project_leads = []
infra_developers = []
sandbox_project_leads = []
sandbox_developers = []

# Domain Configuration
domain_name = "itsandbox.hosei.ac.jp"
create_hosted_zone = false
create_ssl_certificate = false
"""
            
            with open('terraform.tfvars', 'w') as f:
                f.write(tfvars_content)
            
            logger.info("✅ Terraformバックエンド設定生成完了")
            return True
            
        except Exception as e:
            logger.error(f"❌ Terraformバックエンド設定生成失敗: {str(e)}")
            return False
    
    def generate_setup_summary(self, organization_id: Optional[str], policies: Dict[str, str], 
                             roles: Dict[str, str], resources: Dict[str, str]) -> None:
        """セットアップサマリー生成"""
        logger.info("📋 セットアップサマリー生成中...")
        
        summary = {
            'setup_timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'aws_account': self.current_account['Account'],
            'aws_region': self.region,
            'organization_id': organization_id,
            'created_policies': policies,
            'created_roles': roles,
            'created_resources': resources,
            'next_steps': [
                "1. terraform.tfvars ファイルを編集してプロジェクトチーム情報を追加",
                "2. terraform init を実行してバックエンドを初期化",
                "3. terraform plan を実行して設定を確認",
                "4. terraform apply を実行してリソースを作成",
                "5. 新規メンバーをオンボーディング"
            ]
        }
        
        with open('itsandbox-setup-summary.json', 'w') as f:
            json.dump(summary, f, indent=2, default=str)
        
        # マークダウンレポート生成
        md_content = f"""# ITSANDBOX AWS セットアップサマリー

**実行日時**: {summary['setup_timestamp']}  
**AWSアカウント**: {summary['aws_account']}  
**リージョン**: {summary['aws_region']}  
**Organization ID**: {organization_id or 'N/A'}

## 作成されたリソース

### IAMポリシー
"""
        for policy_name, policy_arn in policies.items():
            md_content += f"- **{policy_name}**: `{policy_arn}`\n"
        
        md_content += "\n### IAMロール\n"
        for role_name, role_arn in roles.items():
            md_content += f"- **{role_name}**: `{role_arn}`\n"
        
        md_content += "\n### 共有リソース\n"
        for resource_type, resource_name in resources.items():
            md_content += f"- **{resource_type}**: `{resource_name}`\n"
        
        md_content += f"""
## 次のステップ

{chr(10).join([f"{step}" for step in summary['next_steps']])}

## 重要な注意事項

⚠️ **セキュリティ**
- External ID を安全に保管してください
- Root アカウントのMFAを必ず有効化してください
- アクセスキーの代わりにIAM Roleを使用してください

💰 **コスト管理**
- 月額$100の予算監視が有効です
- 予算の80%に達するとアラートが送信されます
- 不要なリソースは定期的に削除してください

📧 **お問い合わせ**
- 管理者: hoseiitsandbox@gmail.com
"""
        
        with open('ITSANDBOX-Setup-Report.md', 'w') as f:
            f.write(md_content)
        
        logger.info("✅ セットアップサマリー生成完了")

def main():
    """メイン関数"""
    parser = argparse.ArgumentParser(description='ITSANDBOX AWS Setup Script')
    parser.add_argument('--profile', help='AWS profile name')
    parser.add_argument('--region', default='us-east-1', help='AWS region')
    parser.add_argument('--dry-run', action='store_true', help='Dry run mode')
    
    args = parser.parse_args()
    
    print("🚀 ITSANDBOX AWS セットアップスクリプト")
    print("=" * 50)
    
    try:
        # セットアップ初期化
        setup = ITSANDBOXAWSSetup(profile=args.profile, region=args.region)
        
        # 前提条件チェック
        if not setup.check_prerequisites():
            logger.error("❌ 前提条件チェック失敗")
            sys.exit(1)
        
        if args.dry_run:
            logger.info("🧪 ドライランモード - 実際の変更は行いません")
            return
        
        # AWS Organization作成
        organization_id = setup.create_organization()
        
        # OU作成
        ous = setup.create_organizational_units()
        
        # IAMポリシー作成
        policies = setup.setup_iam_policies()
        
        # IAMロール作成
        roles = setup.setup_iam_roles(policies)
        
        # コスト管理設定
        setup.setup_cost_management()
        
        # 共有リソース作成
        resources = setup.setup_shared_resources()
        
        # Terraformバックエンド設定生成
        setup.generate_terraform_backend_config(resources)
        
        # セットアップサマリー生成
        setup.generate_setup_summary(organization_id, policies, roles, resources)
        
        print("\n🎉 ITSANDBOX AWS セットアップ完了!")
        print("=" * 50)
        print("📋 詳細レポート: ITSANDBOX-Setup-Report.md")
        print("⚡ 次のステップ: terraform.tfvars を編集してください")
        
    except KeyboardInterrupt:
        logger.info("⚠️ ユーザーによりキャンセルされました")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ セットアップ失敗: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()