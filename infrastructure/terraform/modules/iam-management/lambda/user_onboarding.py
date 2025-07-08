"""
ITSANDBOX User Onboarding Lambda Function
新規メンバーの自動オンボーディングとアカウント設定
"""

import json
import boto3
import os
import string
import secrets
from datetime import datetime
from typing import Dict, List, Any
import logging

# ログ設定
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
iam_client = boto3.client('iam')
sns_client = boto3.client('sns')
ses_client = boto3.client('ses')

# 環境変数
ADMIN_GROUP_NAME = os.environ.get('ADMIN_GROUP_NAME', 'ITSANDBOXAdmins')
PROJECT_LEAD_GROUP_NAME = os.environ.get('PROJECT_LEAD_GROUP_NAME', 'ITSANDBOXProjectLeads')
DEVELOPER_GROUP_NAME = os.environ.get('DEVELOPER_GROUP_NAME', 'ITSANDBOXDevelopers')
VIEWER_GROUP_NAME = os.environ.get('VIEWER_GROUP_NAME', 'ITSANDBOXViewers')
NOTIFICATION_EMAIL = os.environ.get('NOTIFICATION_EMAIL', '${notification_email}')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
EXTERNAL_ID = os.environ.get('EXTERNAL_ID', '${external_id}')

class ITSANDBOXUserOnboarding:
    def __init__(self):
        self.permissions_boundary_arn = "arn:aws:iam::*:policy/itsandbox/ITSANDBOXPermissionsBoundary"
        
    def create_user(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """新規ユーザーを作成"""
        try:
            username = user_data.get('username')
            email = user_data.get('email')
            role = user_data.get('role', 'Developer')
            project = user_data.get('project', 'general')
            department = user_data.get('department', 'unknown')
            
            # ユーザー名の検証
            if not username or not username.startswith('itsandbox-'):
                raise ValueError("Username must start with 'itsandbox-'")
            
            # ユーザー作成
            user_response = iam_client.create_user(
                UserName=username,
                Path='/itsandbox/',
                PermissionsBoundary=self.permissions_boundary_arn,
                Tags=[
                    {'Key': 'Project', 'Value': project},
                    {'Key': 'Role', 'Value': role},
                    {'Key': 'Email', 'Value': email},
                    {'Key': 'Department', 'Value': department},
                    {'Key': 'CreatedBy', 'Value': 'AutoOnboarding'},
                    {'Key': 'CreatedDate', 'Value': datetime.utcnow().isoformat()},
                    {'Key': 'Owner', 'Value': email},
                    {'Key': 'CostCenter', 'Value': 'ITSANDBOX-Community'}
                ]
            )
            
            logger.info(f"ユーザー {username} を作成しました")
            
            # グループ追加
            group_name = self._get_group_for_role(role)
            if group_name:
                iam_client.add_user_to_group(
                    GroupName=group_name,
                    UserName=username
                )
                logger.info(f"ユーザー {username} をグループ {group_name} に追加しました")
            
            # コンソールアクセス用の初期パスワード生成
            initial_password = self._generate_secure_password()
            
            iam_client.create_login_profile(
                UserName=username,
                Password=initial_password,
                PasswordResetRequired=True
            )
            
            logger.info(f"ユーザー {username} のログインプロファイルを作成しました")
            
            # ウェルカムメール送信
            self._send_welcome_email(username, email, initial_password, role, project)
            
            return {
                'success': True,
                'username': username,
                'initial_password': initial_password,
                'group': group_name,
                'message': f'User {username} created successfully'
            }
            
        except Exception as e:
            logger.error(f"ユーザー作成エラー: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': f'Failed to create user: {str(e)}'
            }
    
    def update_user_role(self, username: str, new_role: str, project: str = None) -> Dict[str, Any]:
        """ユーザーの役割を更新"""
        try:
            # 現在のグループから削除
            current_groups_response = iam_client.get_groups_for_user(UserName=username)
            for group in current_groups_response['Groups']:
                if group['GroupName'].startswith('ITSANDBOX'):
                    iam_client.remove_user_from_group(
                        GroupName=group['GroupName'],
                        UserName=username
                    )
            
            # 新しいグループに追加
            new_group = self._get_group_for_role(new_role)
            if new_group:
                iam_client.add_user_to_group(
                    GroupName=new_group,
                    UserName=username
                )
            
            # ユーザータグを更新
            tags_to_update = [
                {'Key': 'Role', 'Value': new_role},
                {'Key': 'UpdatedDate', 'Value': datetime.utcnow().isoformat()}
            ]
            
            if project:
                tags_to_update.append({'Key': 'Project', 'Value': project})
            
            iam_client.tag_user(
                UserName=username,
                Tags=tags_to_update
            )
            
            logger.info(f"ユーザー {username} の役割を {new_role} に更新しました")
            
            return {
                'success': True,
                'username': username,
                'new_role': new_role,
                'new_group': new_group,
                'message': f'User role updated successfully'
            }
            
        except Exception as e:
            logger.error(f"ユーザー役割更新エラー: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': f'Failed to update user role: {str(e)}'
            }
    
    def deactivate_user(self, username: str, reason: str = 'User requested') -> Dict[str, Any]:
        """ユーザーを無効化"""
        try:
            # アクセスキーを無効化
            try:
                keys_response = iam_client.list_access_keys(UserName=username)
                for key in keys_response['AccessKeyMetadata']:
                    if key['Status'] == 'Active':
                        iam_client.update_access_key(
                            UserName=username,
                            AccessKeyId=key['AccessKeyId'],
                            Status='Inactive'
                        )
                        logger.info(f"アクセスキー {key['AccessKeyId']} を無効化しました")
            except Exception as e:
                logger.warning(f"アクセスキー無効化エラー: {str(e)}")
            
            # ログインプロファイルを削除
            try:
                iam_client.delete_login_profile(UserName=username)
                logger.info(f"ユーザー {username} のログインプロファイルを削除しました")
            except iam_client.exceptions.NoSuchEntityException:
                pass
            
            # 無効化タグを追加
            iam_client.tag_user(
                UserName=username,
                Tags=[
                    {'Key': 'Status', 'Value': 'Deactivated'},
                    {'Key': 'DeactivatedDate', 'Value': datetime.utcnow().isoformat()},
                    {'Key': 'DeactivationReason', 'Value': reason}
                ]
            )
            
            logger.info(f"ユーザー {username} を無効化しました")
            
            return {
                'success': True,
                'username': username,
                'message': f'User {username} deactivated successfully'
            }
            
        except Exception as e:
            logger.error(f"ユーザー無効化エラー: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': f'Failed to deactivate user: {str(e)}'
            }
    
    def rotate_access_keys(self, username: str) -> Dict[str, Any]:
        """ユーザーのアクセスキーをローテーション"""
        try:
            # 既存のアクセスキーを取得
            keys_response = iam_client.list_access_keys(UserName=username)
            existing_keys = keys_response['AccessKeyMetadata']
            
            rotation_results = []
            
            for key in existing_keys:
                if key['Status'] == 'Active':
                    # 新しいアクセスキーを作成
                    new_key_response = iam_client.create_access_key(UserName=username)
                    new_key = new_key_response['AccessKey']
                    
                    # 古いキーを無効化
                    iam_client.update_access_key(
                        UserName=username,
                        AccessKeyId=key['AccessKeyId'],
                        Status='Inactive'
                    )
                    
                    rotation_results.append({
                        'old_key_id': key['AccessKeyId'],
                        'new_key_id': new_key['AccessKeyId'],
                        'new_secret_key': new_key['SecretAccessKey']
                    })
                    
                    logger.info(f"アクセスキー {key['AccessKeyId']} をローテーションしました")
            
            return {
                'success': True,
                'username': username,
                'rotated_keys': len(rotation_results),
                'rotation_results': rotation_results,
                'message': f'Access keys rotated successfully'
            }
            
        except Exception as e:
            logger.error(f"アクセスキーローテーションエラー: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': f'Failed to rotate access keys: {str(e)}'
            }
    
    def bulk_onboard_users(self, users_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """複数ユーザーの一括オンボーディング"""
        try:
            results = {
                'total_users': len(users_data),
                'successful': [],
                'failed': [],
                'summary': {}
            }
            
            for user_data in users_data:
                result = self.create_user(user_data)
                
                if result['success']:
                    results['successful'].append({
                        'username': result['username'],
                        'group': result['group']
                    })
                else:
                    results['failed'].append({
                        'username': user_data.get('username', 'unknown'),
                        'error': result['error']
                    })
            
            results['summary'] = {
                'success_count': len(results['successful']),
                'failure_count': len(results['failed']),
                'success_rate': (len(results['successful']) / len(users_data)) * 100
            }
            
            # 一括オンボーディング結果を通知
            self._send_bulk_onboarding_notification(results)
            
            return results
            
        except Exception as e:
            logger.error(f"一括オンボーディングエラー: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': f'Bulk onboarding failed: {str(e)}'
            }
    
    def _get_group_for_role(self, role: str) -> str:
        """役割に応じたグループ名を取得"""
        role_to_group = {
            'Admin': ADMIN_GROUP_NAME,
            'ProjectLead': PROJECT_LEAD_GROUP_NAME,
            'Developer': DEVELOPER_GROUP_NAME,
            'Viewer': VIEWER_GROUP_NAME
        }
        
        return role_to_group.get(role, DEVELOPER_GROUP_NAME)
    
    def _generate_secure_password(self) -> str:
        """安全な初期パスワードを生成"""
        # パスワード要件: 12文字以上、大文字・小文字・数字・記号を含む
        alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
        
        # 必須文字を含める
        password = [
            secrets.choice(string.ascii_lowercase),  # 小文字
            secrets.choice(string.ascii_uppercase),  # 大文字
            secrets.choice(string.digits),           # 数字
            secrets.choice("!@#$%^&*")              # 記号
        ]
        
        # 残りの文字をランダムに追加
        for i in range(8):  # 合計12文字
            password.append(secrets.choice(alphabet))
        
        # パスワードをシャッフル
        secrets.SystemRandom().shuffle(password)
        
        return ''.join(password)
    
    def _send_welcome_email(self, username: str, email: str, password: str, role: str, project: str):
        """ウェルカムメール送信"""
        try:
            subject = "🎉 ITSANDBOX へようこそ！アカウント情報"
            
            body = f"""
法政大学 IT Innovation Community ITSANDBOXへようこそ！

アカウントが正常に作成されました。

📋 アカウント情報:
• ユーザー名: {username}
• メールアドレス: {email}
• 役割: {role}
• プロジェクト: {project}
• 初期パスワード: {password}

🔐 セキュリティ重要事項:
• 初回ログイン時にパスワード変更が必要です
• MFA（多要素認証）の設定を強く推奨します
• アクセスキーが必要な場合は管理者にお問い合わせください

🌐 AWSコンソールアクセス:
• URL: https://aws.amazon.com/console/
• アカウントID: [管理者から別途連絡]

📚 ITSANDBOXリソース:
• GitHub: https://github.com/hosei-itsandbox
• ドキュメント: [準備中]
• お問い合わせ: {NOTIFICATION_EMAIL}

🎯 次のステップ:
1. AWSコンソールにログイン
2. パスワード変更
3. MFA設定
4. プロジェクトチームへの参加

ITSANDBOXコミュニティの一員として、一緒に素晴らしいものを作りましょう！

法政大学 IT Innovation Community
ITSANDBOX 管理チーム
"""
            
            # SES経由でメール送信
            ses_client.send_email(
                Source=NOTIFICATION_EMAIL,
                Destination={'ToAddresses': [email]},
                Message={
                    'Subject': {'Data': subject},
                    'Body': {'Text': {'Data': body}}
                }
            )
            
            logger.info(f"ウェルカムメールを {email} に送信しました")
            
        except Exception as e:
            logger.error(f"ウェルカムメール送信エラー: {str(e)}")
    
    def _send_bulk_onboarding_notification(self, results: Dict[str, Any]):
        """一括オンボーディング結果通知"""
        try:
            subject = "📊 ITSANDBOX 一括オンボーディング結果"
            
            body = f"""
ITSANDBOX 一括ユーザーオンボーディングが完了しました。

📊 実行結果:
• 処理対象ユーザー数: {results['total_users']}
• 成功: {results['summary']['success_count']}
• 失敗: {results['summary']['failure_count']}
• 成功率: {results['summary']['success_rate']:.1f}%

✅ 成功したユーザー:
"""
            
            for user in results['successful']:
                body += f"• {user['username']} ({user['group']})\n"
            
            if results['failed']:
                body += f"\n❌ 失敗したユーザー:\n"
                for user in results['failed']:
                    body += f"• {user['username']}: {user['error']}\n"
            
            body += f"\n実行時刻: {datetime.utcnow().isoformat()}"
            
            # SNS通知
            if SNS_TOPIC_ARN:
                sns_client.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject=subject,
                    Message=body
                )
            
            logger.info("一括オンボーディング結果通知を送信しました")
            
        except Exception as e:
            logger.error(f"一括オンボーディング通知エラー: {str(e)}")

def lambda_handler(event, context):
    """Lambda エントリーポイント"""
    try:
        onboarding = ITSANDBOXUserOnboarding()
        action = event.get('action', 'create_user')
        
        if action == 'create_user':
            user_data = event.get('user_data', {})
            result = onboarding.create_user(user_data)
            
            return {
                'statusCode': 200 if result['success'] else 400,
                'body': json.dumps(result)
            }
        
        elif action == 'update_role':
            username = event.get('username')
            new_role = event.get('new_role')
            project = event.get('project')
            
            result = onboarding.update_user_role(username, new_role, project)
            
            return {
                'statusCode': 200 if result['success'] else 400,
                'body': json.dumps(result)
            }
        
        elif action == 'deactivate_user':
            username = event.get('username')
            reason = event.get('reason', 'Administrative action')
            
            result = onboarding.deactivate_user(username, reason)
            
            return {
                'statusCode': 200 if result['success'] else 400,
                'body': json.dumps(result)
            }
        
        elif action == 'rotate_keys':
            username = event.get('username')
            result = onboarding.rotate_access_keys(username)
            
            return {
                'statusCode': 200 if result['success'] else 400,
                'body': json.dumps(result)
            }
        
        elif action == 'bulk_onboard':
            users_data = event.get('users_data', [])
            result = onboarding.bulk_onboard_users(users_data)
            
            return {
                'statusCode': 200,
                'body': json.dumps(result)
            }
        
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'success': False,
                    'message': f'Unknown action: {action}'
                })
            }
        
    except Exception as e:
        logger.error(f"Lambda実行エラー: {str(e)}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'success': False,
                'error': str(e),
                'message': 'User onboarding failed'
            })
        }

# ローカルテスト用
if __name__ == "__main__":
    test_event = {
        "action": "create_user",
        "user_data": {
            "username": "itsandbox-test-user",
            "email": "test@hosei.ac.jp",
            "role": "Developer",
            "project": "website",
            "department": "経営システム工学科"
        }
    }
    test_context = {}
    result = lambda_handler(test_event, test_context)
    print(json.dumps(result, indent=2))