# ITSANDBOX AWS セットアップガイド

## 🎯 概要

このディレクトリには、ITSANDBOXコミュニティのAWS環境を自動セットアップするためのスクリプトとツールが含まれています。MCPサーバーから取得したAWS公式ドキュメントのベストプラクティスを活用して構築されています。

## 📁 ファイル構成

```
scripts/
├── setup-aws-organization.sh    # AWS Organization自動セットアップ（Bash）
├── mcp-setup-aws.py            # MCP対応Pythonセットアップスクリプト
├── requirements.txt             # Python依存関係
└── README.md                   # このファイル
```

## 🚀 セットアップ手順

### 1. 前提条件

**必要なツール:**
- Python 3.9+
- AWS CLI v2
- jq
- 適切なAWS権限を持つアカウント

**必要なAWS権限:**
- Organizations: CreateOrganization, ListRoots, CreateOrganizationalUnit
- IAM: CreateRole, CreatePolicy, AttachRolePolicy
- Budgets: CreateBudget, CreateNotification
- S3: CreateBucket, PutBucketEncryption
- DynamoDB: CreateTable

### 2. AWS認証情報設定

```bash
# AWS CLI設定
aws configure

# または特定のプロファイル使用
aws configure --profile itsandbox
```

### 3. Python環境準備

```bash
# 仮想環境作成（推奨）
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate    # Windows

# 依存関係インストール
pip install -r requirements.txt
```

### 4. セットアップ実行

#### Option A: Python スクリプト（推奨）

```bash
# 基本実行
python mcp-setup-aws.py

# プロファイル指定
python mcp-setup-aws.py --profile itsandbox

# リージョン指定
python mcp-setup-aws.py --region ap-northeast-1

# ドライラン
python mcp-setup-aws.py --dry-run
```

#### Option B: Bash スクリプト

```bash
# 実行権限付与
chmod +x setup-aws-organization.sh

# 実行
./setup-aws-organization.sh
```

### 5. Terraform適用

```bash
# セットアップ完了後
cd ../../terraform/environments/production

# terraform.tfvars を編集
# - プロジェクトチーム情報を追加
# - organization_id を更新

# Terraform初期化
terraform init

# 設定確認
terraform plan

# 適用
terraform apply
```

## 📋 セットアップ内容

### 自動作成されるAWSリソース

1. **AWS Organization**
   - Feature Set: ALL
   - Organizational Units: Core, Projects, Sandbox

2. **IAM Policies**
   - ITSANDBOXDeveloperPolicy
   - ITSANDBOXPermissionsBoundary

3. **IAM Roles**
   - ITSANDBOXDeveloperRole（Cross-account access対応）

4. **コスト管理**
   - 月額$100予算
   - 80%使用時のアラート通知

5. **共有リソース**
   - S3バケット（Terraform State用）
   - DynamoDBテーブル（Terraform Lock用）

### 自動生成されるファイル

- `terraform-backend.tf` - Terraformバックエンド設定
- `terraform.tfvars` - Terraform変数（要編集）
- `organization-info.json` - Organization情報
- `itsandbox-setup-summary.json` - セットアップサマリー
- `ITSANDBOX-Setup-Report.md` - 詳細レポート

## 🔧 設定オプション

### mcp-setup-aws.py オプション

| オプション | 説明 | デフォルト |
|-----------|------|------------|
| `--profile` | AWS CLI プロファイル | default |
| `--region` | AWS リージョン | us-east-1 |
| `--dry-run` | ドライランモード | false |

### 環境変数

```bash
# オプション: デバッグレベル設定
export PYTHONPATH=/path/to/itsandbox
export AWS_DEFAULT_REGION=us-east-1
export AWS_DEFAULT_OUTPUT=json
```

## 🛡️ セキュリティ考慮事項

### 1. 権限最小化
- スクリプトは必要最小限の権限のみ要求
- Permissions Boundaryで権限制限

### 2. 暗号化
- S3バケットはAES-256暗号化
- DynamoDBテーブルは保存時暗号化

### 3. アクセス制御
- パブリックアクセス完全ブロック
- Cross-account access用External ID

### 4. 監査証跡
- 全てのリソースにタグ付け
- セットアップログ記録

## 💰 コスト管理

### 予算設定
- **月額上限**: $100
- **アラート**: 80%到達時
- **通知先**: hoseiitsandbox@gmail.com

### 無料利用枠活用
- Lambda: 100万リクエスト/月
- DynamoDB: 25GB/月
- S3: 5GB/月
- CloudWatch: 基本メトリクス

## 🔍 トラブルシューティング

### よくあるエラー

#### 1. 権限不足エラー
```
AccessDenied: User is not authorized to perform organizations:CreateOrganization
```
**解決方法**: AWS管理者にOrganizations権限を依頼

#### 2. リージョンエラー
```
InvalidLocationConstraint: The specified location constraint is not valid
```
**解決方法**: `--region` オプションで正しいリージョンを指定

#### 3. 重複リソースエラー
```
BucketAlreadyExists: The requested bucket name is not available
```
**解決方法**: スクリプトが自動的に一意な名前を生成します

### ログ確認

```bash
# 詳細ログ出力
export PYTHONPATH=/path/to/itsandbox
python -u mcp-setup-aws.py --region us-east-1 2>&1 | tee setup.log
```

### 設定確認

```bash
# AWS設定確認
aws sts get-caller-identity

# Organization確認
aws organizations describe-organization

# 作成されたリソース確認
aws iam list-roles --path-prefix /itsandbox/
aws s3 ls | grep itsandbox
```

## 🆘 サポート

### 問題報告
- **Email**: hoseiitsandbox@gmail.com
- **GitHub Issues**: プロジェクトリポジトリ

### 追加リソース
- [AWS Organizations User Guide](https://docs.aws.amazon.com/organizations/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📚 参考資料

このセットアップスクリプトは、以下のAWS公式ドキュメントとベストプラクティスに基づいています：

- AWS SDK Examples Repository（信頼度9.7、2435個のコード例）
- AWS Organizations API Reference
- AWS IAM Policy Examples
- AWS Cost Management Best Practices

---

**🎓 法政大学 IT Innovation Community - ITSANDBOX**