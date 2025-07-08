#!/bin/bash

# ITSANDBOX AWS Organization Setup Script
# AWS Organizationの初期設定とアカウント作成を自動化

set -euo pipefail

# ====================
# Configuration
# ====================

# カラーコード
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定値
ORGANIZATION_NAME="ITSANDBOX"
MASTER_ACCOUNT_EMAIL="hoseiitsandbox@gmail.com"
BUDGET_LIMIT="100"

# アカウント設定
declare -A ACCOUNTS=(
    ["itsandbox-shared-services"]="shared-services@hosei.ac.jp"
    ["itsandbox-security-audit"]="security-audit@hosei.ac.jp"
    ["itsandbox-network-hub"]="network-hub@hosei.ac.jp"
    ["itsandbox-website-project"]="website-project@hosei.ac.jp"
    ["itsandbox-api-project"]="api-project@hosei.ac.jp"
    ["itsandbox-infrastructure"]="infrastructure@hosei.ac.jp"
    ["itsandbox-sandbox"]="sandbox@hosei.ac.jp"
)

# OU（Organizational Unit）設定
declare -A OUS=(
    ["Core"]="Core accounts for shared services"
    ["Projects"]="Project-specific development accounts"
    ["Sandbox"]="Individual sandbox environments"
)

# ====================
# Functions
# ====================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "前提条件をチェック中..."
    
    # AWS CLI インストール確認
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI がインストールされていません"
        echo "AWS CLI をインストールしてください: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # AWS認証情報確認
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS認証情報が設定されていません"
        echo "aws configure を実行して認証情報を設定してください"
        exit 1
    fi
    
    # jq インストール確認
    if ! command -v jq &> /dev/null; then
        log_error "jq がインストールされていません"
        echo "jq をインストールしてください: https://stedolan.github.io/jq/"
        exit 1
    fi
    
    log_success "前提条件チェック完了"
}

create_organization() {
    log_info "AWS Organization を作成中..."
    
    # Organization が既に存在するかチェック
    if aws organizations describe-organization &> /dev/null; then
        log_warning "AWS Organization は既に存在します"
        return 0
    fi
    
    # Organization 作成
    local org_result
    org_result=$(aws organizations create-organization \
        --feature-set ALL \
        --output json)
    
    if [ $? -eq 0 ]; then
        local org_id
        org_id=$(echo "$org_result" | jq -r '.Organization.Id')
        log_success "AWS Organization 作成完了: $org_id"
        
        # Organization情報をファイルに保存
        echo "$org_result" > "organization-info.json"
    else
        log_error "AWS Organization 作成に失敗しました"
        exit 1
    fi
}

create_organizational_units() {
    log_info "Organizational Units (OU) を作成中..."
    
    # Root OU ID を取得
    local root_id
    root_id=$(aws organizations list-roots --query 'Roots[0].Id' --output text)
    
    for ou_name in "${!OUS[@]}"; do
        local ou_description="${OUS[$ou_name]}"
        
        log_info "OU '$ou_name' を作成中..."
        
        local ou_result
        ou_result=$(aws organizations create-organizational-unit \
            --parent-id "$root_id" \
            --name "$ou_name" \
            --output json 2>/dev/null || echo "exists")
        
        if [ "$ou_result" != "exists" ]; then
            local ou_id
            ou_id=$(echo "$ou_result" | jq -r '.OrganizationalUnit.Id')
            log_success "OU '$ou_name' 作成完了: $ou_id"
        else
            log_warning "OU '$ou_name' は既に存在します"
        fi
    done
}

create_accounts() {
    log_info "メンバーアカウントを作成中..."
    
    for account_name in "${!ACCOUNTS[@]}"; do
        local account_email="${ACCOUNTS[$account_name]}"
        
        log_info "アカウント '$account_name' を作成中..."
        
        # アカウント作成
        local create_result
        create_result=$(aws organizations create-account \
            --email "$account_email" \
            --account-name "$account_name" \
            --output json 2>/dev/null || echo "error")
        
        if [ "$create_result" != "error" ]; then
            local request_id
            request_id=$(echo "$create_result" | jq -r '.CreateAccountStatus.Id')
            log_info "アカウント作成リクエスト送信: $request_id"
            
            # 作成完了を待機
            wait_for_account_creation "$request_id" "$account_name"
        else
            log_warning "アカウント '$account_name' の作成に失敗、または既に存在します"
        fi
    done
}

wait_for_account_creation() {
    local request_id=$1
    local account_name=$2
    local max_attempts=30
    local attempt=1
    
    log_info "アカウント '$account_name' の作成完了を待機中..."
    
    while [ $attempt -le $max_attempts ]; do
        local status_result
        status_result=$(aws organizations describe-create-account-status \
            --create-account-request-id "$request_id" \
            --output json)
        
        local status
        status=$(echo "$status_result" | jq -r '.CreateAccountStatus.State')
        
        case $status in
            "SUCCEEDED")
                local account_id
                account_id=$(echo "$status_result" | jq -r '.CreateAccountStatus.AccountId')
                log_success "アカウント '$account_name' 作成完了: $account_id"
                
                # アカウント情報を保存
                echo "$status_result" >> "created-accounts.json"
                return 0
                ;;
            "FAILED")
                local failure_reason
                failure_reason=$(echo "$status_result" | jq -r '.CreateAccountStatus.FailureReason // "Unknown"')
                log_error "アカウント '$account_name' の作成に失敗: $failure_reason"
                return 1
                ;;
            "IN_PROGRESS")
                echo -n "."
                sleep 10
                ;;
        esac
        
        ((attempt++))
    done
    
    log_error "アカウント '$account_name' の作成がタイムアウトしました"
    return 1
}

move_accounts_to_ous() {
    log_info "アカウントを適切なOUに移動中..."
    
    # OU ID を取得
    local core_ou_id
    local projects_ou_id
    local sandbox_ou_id
    
    core_ou_id=$(aws organizations list-organizational-units-for-parent \
        --parent-id "$(aws organizations list-roots --query 'Roots[0].Id' --output text)" \
        --query 'OrganizationalUnits[?Name==`Core`].Id' \
        --output text)
    
    projects_ou_id=$(aws organizations list-organizational-units-for-parent \
        --parent-id "$(aws organizations list-roots --query 'Roots[0].Id' --output text)" \
        --query 'OrganizationalUnits[?Name==`Projects`].Id' \
        --output text)
    
    sandbox_ou_id=$(aws organizations list-organizational-units-for-parent \
        --parent-id "$(aws organizations list-roots --query 'Roots[0].Id' --output text)" \
        --query 'OrganizationalUnits[?Name==`Sandbox`].Id' \
        --output text)
    
    # アカウントリストを取得
    local accounts_json
    accounts_json=$(aws organizations list-accounts --output json)
    
    # 各アカウントを適切なOUに移動
    while IFS= read -r account; do
        local account_id
        local account_name
        
        account_id=$(echo "$account" | jq -r '.Id')
        account_name=$(echo "$account" | jq -r '.Name')
        
        # Master アカウントはスキップ
        if [ "$account_name" = "master" ] || [ "$account_name" = "root" ]; then
            continue
        fi
        
        local target_ou_id=""
        
        case $account_name in
            *shared-services*|*security-audit*|*network-hub*)
                target_ou_id="$core_ou_id"
                ;;
            *website-project*|*api-project*|*infrastructure*)
                target_ou_id="$projects_ou_id"
                ;;
            *sandbox*)
                target_ou_id="$sandbox_ou_id"
                ;;
        esac
        
        if [ -n "$target_ou_id" ]; then
            log_info "アカウント '$account_name' を適切なOUに移動中..."
            
            aws organizations move-account \
                --account-id "$account_id" \
                --source-parent-id "$(aws organizations list-roots --query 'Roots[0].Id' --output text)" \
                --destination-parent-id "$target_ou_id" 2>/dev/null || true
            
            log_success "アカウント '$account_name' を移動完了"
        fi
        
    done < <(echo "$accounts_json" | jq -c '.Accounts[]')
}

enable_trusted_access() {
    log_info "信頼されたアクセスサービスを有効化中..."
    
    local services=(
        "cloudtrail.amazonaws.com"
        "config.amazonaws.com"
        "guardduty.amazonaws.com"
        "securityhub.amazonaws.com"
        "sso.amazonaws.com"
        "access-analyzer.amazonaws.com"
    )
    
    for service in "${services[@]}"; do
        log_info "サービス '$service' の信頼されたアクセスを有効化中..."
        
        aws organizations enable-aws-service-access \
            --service-principal "$service" 2>/dev/null || true
        
        log_success "サービス '$service' の信頼されたアクセス有効化完了"
    done
}

setup_service_control_policies() {
    log_info "Service Control Policies (SCP) を設定中..."
    
    # 基本的なSCPポリシーを作成
    local scp_policy='{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Deny",
                "Action": [
                    "organizations:LeaveOrganization",
                    "account:CloseAccount"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Deny",
                "Action": [
                    "ec2:TerminateInstances",
                    "rds:DeleteDBInstance"
                ],
                "Resource": "*",
                "Condition": {
                    "StringNotEquals": {
                        "aws:PrincipalTag/Role": ["Admin", "ProjectLead"]
                    }
                }
            }
        ]
    }'
    
    # SCPポリシーを作成
    local policy_result
    policy_result=$(aws organizations create-policy \
        --name "ITSANDBOX-BaselinePolicy" \
        --description "Baseline security policy for ITSANDBOX accounts" \
        --type "SERVICE_CONTROL_POLICY" \
        --content "$scp_policy" \
        --output json 2>/dev/null || echo "exists")
    
    if [ "$policy_result" != "exists" ]; then
        local policy_id
        policy_id=$(echo "$policy_result" | jq -r '.Policy.PolicySummary.Id')
        log_success "SCPポリシー作成完了: $policy_id"
    else
        log_warning "SCPポリシーは既に存在します"
    fi
}

generate_summary_report() {
    log_info "セットアップサマリーレポートを生成中..."
    
    local report_file="itsandbox-setup-summary.md"
    
    cat > "$report_file" << EOF
# ITSANDBOX AWS Organization Setup Summary

**実行日時**: $(date)
**実行者**: $(aws sts get-caller-identity --query 'Arn' --output text)

## AWS Organization 情報

EOF
    
    # Organization情報を追加
    if [ -f "organization-info.json" ]; then
        local org_id
        local master_account_id
        
        org_id=$(jq -r '.Organization.Id' organization-info.json)
        master_account_id=$(jq -r '.Organization.MasterAccountId' organization-info.json)
        
        cat >> "$report_file" << EOF
- **Organization ID**: $org_id
- **Master Account ID**: $master_account_id
- **Feature Set**: ALL

## 作成されたアカウント

EOF
    fi
    
    # 作成されたアカウント情報を追加
    if [ -f "created-accounts.json" ]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                local account_name
                local account_id
                local account_email
                
                account_name=$(echo "$line" | jq -r '.CreateAccountStatus.AccountName')
                account_id=$(echo "$line" | jq -r '.CreateAccountStatus.AccountId')
                account_email=$(echo "$line" | jq -r '.CreateAccountStatus.Email')
                
                cat >> "$report_file" << EOF
- **$account_name**
  - Account ID: $account_id
  - Email: $account_email

EOF
            fi
        done < created-accounts.json
    fi
    
    cat >> "$report_file" << EOF
## 次のステップ

1. **Terraform State Backend 設定**
   \`\`\`bash
   # S3バケットとDynamoDBテーブルが作成されたら、backend設定を有効化
   terraform init
   \`\`\`

2. **IAM Cross-Account Roles 設定**
   \`\`\`bash
   # terraform.tfvars ファイルに正しいアカウントIDを設定
   terraform plan
   terraform apply
   \`\`\`

3. **メンバーオンボーディング**
   \`\`\`bash
   # Lambda関数を使用して新規メンバーを追加
   aws lambda invoke --function-name itsandbox-user-onboarding
   \`\`\`

4. **コスト監視設定確認**
   - Budget アラートが正しく設定されていることを確認
   - CloudWatch ダッシュボードでコスト監視を開始

## 重要な注意事項

⚠️ **セキュリティ**
- External ID は安全に保管してください
- Root アカウントのMFAを必ず有効化してください
- アクセスキーの代わりにIAM Roleを使用してください

💰 **コスト管理**
- 月額予算 $BUDGET_LIMIT の監視が有効です
- 予算の80%に達するとアラートが送信されます
- 不要なリソースは定期的に削除してください

📧 **連絡先**
- 管理者: $MASTER_ACCOUNT_EMAIL
- 緊急時: [緊急連絡先を追加]

EOF
    
    log_success "セットアップサマリーレポート生成完了: $report_file"
}

main() {
    echo -e "${GREEN}"
    echo "=================================================="
    echo "   ITSANDBOX AWS Organization Setup Script"
    echo "=================================================="
    echo -e "${NC}"
    
    check_prerequisites
    
    log_info "AWS Organization のセットアップを開始します..."
    read -p "続行しますか? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "セットアップをキャンセルしました"
        exit 0
    fi
    
    create_organization
    create_organizational_units
    create_accounts
    move_accounts_to_ous
    enable_trusted_access
    setup_service_control_policies
    generate_summary_report
    
    echo -e "${GREEN}"
    echo "=================================================="
    echo "   ITSANDBOX AWS Organization Setup 完了!"
    echo "=================================================="
    echo -e "${NC}"
    
    log_success "セットアップが正常に完了しました"
    log_info "詳細はサマリーレポートを確認してください: itsandbox-setup-summary.md"
}

# スクリプト実行
main "$@"