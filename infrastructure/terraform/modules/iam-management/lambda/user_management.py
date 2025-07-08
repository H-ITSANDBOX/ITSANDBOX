"""
ITSANDBOX User Management Lambda Function
自動ユーザー管理、監査、セキュリティチェック
"""

import json
import boto3
import os
from datetime import datetime, timedelta
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
ORGANIZATION_ID = os.environ.get('ORGANIZATION_ID', '')
MASTER_ACCOUNT_ID = os.environ.get('MASTER_ACCOUNT_ID', '')
UNUSED_USER_THRESHOLD_DAYS = int(os.environ.get('UNUSED_USER_THRESHOLD_DAYS', '90'))
ACCESS_KEY_ROTATION_DAYS = int(os.environ.get('ACCESS_KEY_ROTATION_DAYS', '90'))
NOTIFICATION_EMAIL = os.environ.get('NOTIFICATION_EMAIL', '${notification_email}')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')

class ITSANDBOXUserManager:
    def __init__(self):
        self.current_date = datetime.utcnow()
        self.unused_threshold = self.current_date - timedelta(days=UNUSED_USER_THRESHOLD_DAYS)
        self.rotation_threshold = self.current_date - timedelta(days=ACCESS_KEY_ROTATION_DAYS)
    
    def audit_users(self) -> Dict[str, Any]:
        """ユーザー監査を実行"""
        try:
            # 全ユーザーリストを取得
            users_response = iam_client.list_users(PathPrefix='/itsandbox/')
            users = users_response['Users']
            
            audit_results = {
                'total_users': len(users),
                'unused_users': [],
                'users_without_mfa': [],
                'users_with_old_passwords': [],
                'users_with_excessive_permissions': [],
                'compliance_violations': []
            }
            
            for user in users:
                username = user['UserName']
                
                # 未使用ユーザーチェック
                if self._is_user_unused(user):
                    audit_results['unused_users'].append({
                        'username': username,
                        'last_activity': self._get_user_last_activity(username),
                        'created_date': user['CreateDate'].isoformat()
                    })
                
                # MFAチェック
                if not self._has_mfa_enabled(username):
                    audit_results['users_without_mfa'].append(username)
                
                # パスワード年齢チェック
                password_age = self._get_password_age(username)
                if password_age and password_age > 90:
                    audit_results['users_with_old_passwords'].append({
                        'username': username,
                        'password_age_days': password_age
                    })
                
                # 権限過多チェック
                if self._has_excessive_permissions(username):
                    audit_results['users_with_excessive_permissions'].append(username)
                
                # コンプライアンス違反チェック
                violations = self._check_compliance_violations(username)
                if violations:
                    audit_results['compliance_violations'].append({
                        'username': username,
                        'violations': violations
                    })
            
            return audit_results
            
        except Exception as e:
            logger.error(f"ユーザー監査エラー: {str(e)}")
            return {'error': str(e)}
    
    def audit_access_keys(self) -> Dict[str, Any]:
        """アクセスキー監査を実行"""
        try:
            users_response = iam_client.list_users(PathPrefix='/itsandbox/')
            users = users_response['Users']
            
            key_audit_results = {
                'total_users_checked': len(users),
                'users_with_old_keys': [],
                'users_with_unused_keys': [],
                'users_with_multiple_keys': [],
                'rotation_recommendations': []
            }
            
            for user in users:
                username = user['UserName']
                
                try:
                    # ユーザーのアクセスキーを取得
                    keys_response = iam_client.list_access_keys(UserName=username)
                    access_keys = keys_response['AccessKeyMetadata']
                    
                    if len(access_keys) > 1:
                        key_audit_results['users_with_multiple_keys'].append({
                            'username': username,
                            'key_count': len(access_keys)
                        })
                    
                    for key in access_keys:
                        key_age = (self.current_date - key['CreateDate'].replace(tzinfo=None)).days
                        
                        # 古いキーのチェック
                        if key_age > ACCESS_KEY_ROTATION_DAYS:
                            key_audit_results['users_with_old_keys'].append({
                                'username': username,
                                'access_key_id': key['AccessKeyId'],
                                'age_days': key_age,
                                'status': key['Status']
                            })
                        
                        # 未使用キーのチェック
                        if key['Status'] == 'Active':
                            last_used = self._get_access_key_last_used(key['AccessKeyId'])
                            if last_used and (self.current_date - last_used).days > 30:
                                key_audit_results['users_with_unused_keys'].append({
                                    'username': username,
                                    'access_key_id': key['AccessKeyId'],
                                    'last_used': last_used.isoformat(),
                                    'unused_days': (self.current_date - last_used).days
                                })
                
                except Exception as e:
                    logger.warning(f"ユーザー {username} のアクセスキーチェックに失敗: {str(e)}")
            
            return key_audit_results
            
        except Exception as e:
            logger.error(f"アクセスキー監査エラー: {str(e)}")
            return {'error': str(e)}
    
    def _is_user_unused(self, user: Dict) -> bool:
        """ユーザーが未使用かどうかを判定"""
        try:
            username = user['UserName']
            
            # パスワードによるログイン履歴をチェック
            try:
                login_profile = iam_client.get_login_profile(UserName=username)
                password_last_used = login_profile.get('LoginProfile', {}).get('PasswordLastUsed')
                
                if password_last_used:
                    if password_last_used.replace(tzinfo=None) < self.unused_threshold:
                        return True
                else:
                    # パスワードが一度も使用されていない場合
                    create_date = user['CreateDate'].replace(tzinfo=None)
                    if create_date < self.unused_threshold:
                        return True
            except iam_client.exceptions.NoSuchEntityException:
                # コンソールアクセスなし（プログラムアクセスのみ）
                pass
            
            # アクセスキーの使用履歴をチェック
            try:
                keys_response = iam_client.list_access_keys(UserName=username)
                for key in keys_response['AccessKeyMetadata']:
                    last_used = self._get_access_key_last_used(key['AccessKeyId'])
                    if last_used and last_used > self.unused_threshold:
                        return False
            except Exception:
                pass
            
            return True
            
        except Exception as e:
            logger.warning(f"ユーザー {user['UserName']} の使用状況チェックに失敗: {str(e)}")
            return False
    
    def _get_user_last_activity(self, username: str) -> str:
        """ユーザーの最終アクティビティを取得"""
        try:
            # パスワードによるログイン
            try:
                login_profile = iam_client.get_login_profile(UserName=username)
                password_last_used = login_profile.get('LoginProfile', {}).get('PasswordLastUsed')
                if password_last_used:
                    return password_last_used.isoformat()
            except iam_client.exceptions.NoSuchEntityException:
                pass
            
            # アクセスキーによるアクセス
            try:
                keys_response = iam_client.list_access_keys(UserName=username)
                latest_access = None
                
                for key in keys_response['AccessKeyMetadata']:
                    last_used = self._get_access_key_last_used(key['AccessKeyId'])
                    if last_used and (not latest_access or last_used > latest_access):
                        latest_access = last_used
                
                if latest_access:
                    return latest_access.isoformat()
            except Exception:
                pass
            
            return "Never"
            
        except Exception as e:
            logger.warning(f"ユーザー {username} の最終アクティビティ取得に失敗: {str(e)}")
            return "Unknown"
    
    def _get_access_key_last_used(self, access_key_id: str) -> datetime:
        """アクセスキーの最終使用日時を取得"""
        try:
            response = iam_client.get_access_key_last_used(AccessKeyId=access_key_id)
            last_used_date = response.get('AccessKeyLastUsed', {}).get('LastUsedDate')
            
            if last_used_date:
                return last_used_date.replace(tzinfo=None)
            
            return None
            
        except Exception as e:
            logger.warning(f"アクセスキー {access_key_id} の最終使用日時取得に失敗: {str(e)}")
            return None
    
    def _has_mfa_enabled(self, username: str) -> bool:
        """ユーザーのMFA設定状況をチェック"""
        try:
            response = iam_client.list_mfa_devices(UserName=username)
            return len(response['MFADevices']) > 0
        except Exception as e:
            logger.warning(f"ユーザー {username} のMFAチェックに失敗: {str(e)}")
            return False
    
    def _get_password_age(self, username: str) -> int:
        """パスワードの年齢（日数）を取得"""
        try:
            login_profile = iam_client.get_login_profile(UserName=username)
            create_date = login_profile['LoginProfile']['CreateDate'].replace(tzinfo=None)
            return (self.current_date - create_date).days
        except iam_client.exceptions.NoSuchEntityException:
            return None
        except Exception as e:
            logger.warning(f"ユーザー {username} のパスワード年齢取得に失敗: {str(e)}")
            return None
    
    def _has_excessive_permissions(self, username: str) -> bool:
        """ユーザーの権限過多をチェック"""
        try:
            # 直接アタッチされたポリシーをチェック
            attached_policies = iam_client.list_attached_user_policies(UserName=username)
            
            # 管理者権限ポリシーのチェック
            admin_policies = [
                'arn:aws:iam::aws:policy/AdministratorAccess',
                'arn:aws:iam::aws:policy/PowerUserAccess'
            ]
            
            for policy in attached_policies['AttachedPolicies']:
                if policy['PolicyArn'] in admin_policies:
                    return True
            
            # インラインポリシーのチェック
            inline_policies = iam_client.list_user_policies(UserName=username)
            if len(inline_policies['PolicyNames']) > 0:
                return True
            
            return False
            
        except Exception as e:
            logger.warning(f"ユーザー {username} の権限チェックに失敗: {str(e)}")
            return False
    
    def _check_compliance_violations(self, username: str) -> List[str]:
        """コンプライアンス違反をチェック"""
        violations = []
        
        try:
            # 必須タグのチェック
            try:
                user_tags_response = iam_client.list_user_tags(UserName=username)
                user_tags = {tag['Key']: tag['Value'] for tag in user_tags_response['Tags']}
                
                required_tags = ['Project', 'Owner', 'Role']
                for required_tag in required_tags:
                    if required_tag not in user_tags:
                        violations.append(f"Required tag '{required_tag}' is missing")
            except Exception:
                violations.append("Unable to check user tags")
            
            # 命名規則のチェック
            if not username.startswith('itsandbox-'):
                violations.append("Username does not follow naming convention (should start with 'itsandbox-')")
            
            # グループメンバーシップのチェック
            try:
                groups_response = iam_client.get_groups_for_user(UserName=username)
                groups = [group['GroupName'] for group in groups_response['Groups']]
                
                itsandbox_groups = [g for g in groups if g.startswith('ITSANDBOX')]
                if not itsandbox_groups:
                    violations.append("User is not member of any ITSANDBOX groups")
            except Exception:
                violations.append("Unable to check group membership")
            
        except Exception as e:
            logger.warning(f"ユーザー {username} のコンプライアンスチェックに失敗: {str(e)}")
            violations.append(f"Compliance check failed: {str(e)}")
        
        return violations
    
    def create_audit_report(self, audit_results: Dict[str, Any], key_audit_results: Dict[str, Any]) -> str:
        """監査レポートを生成"""
        report = f"""
🔐 ITSANDBOX IAM セキュリティ監査レポート
実行日時: {self.current_date.strftime('%Y-%m-%d %H:%M UTC')}

📊 ユーザー監査結果:
• 総ユーザー数: {audit_results.get('total_users', 0)}
• 未使用ユーザー: {len(audit_results.get('unused_users', []))}
• MFA未設定ユーザー: {len(audit_results.get('users_without_mfa', []))}
• 古いパスワードのユーザー: {len(audit_results.get('users_with_old_passwords', []))}
• 権限過多ユーザー: {len(audit_results.get('users_with_excessive_permissions', []))}
• コンプライアンス違反: {len(audit_results.get('compliance_violations', []))}

🔑 アクセスキー監査結果:
• チェック対象ユーザー数: {key_audit_results.get('total_users_checked', 0)}
• 古いキーを持つユーザー: {len(key_audit_results.get('users_with_old_keys', []))}
• 未使用キーを持つユーザー: {len(key_audit_results.get('users_with_unused_keys', []))}
• 複数キーを持つユーザー: {len(key_audit_results.get('users_with_multiple_keys', []))}

⚠️ 要対応項目:"""

        # 詳細な要対応項目
        if audit_results.get('unused_users'):
            report += f"\n\n🚫 未使用ユーザー ({len(audit_results['unused_users'])}):"
            for user in audit_results['unused_users'][:5]:  # 最大5件表示
                report += f"\n• {user['username']} (最終活動: {user['last_activity']})"
            if len(audit_results['unused_users']) > 5:
                report += f"\n• ... 他{len(audit_results['unused_users']) - 5}件"
        
        if audit_results.get('users_without_mfa'):
            report += f"\n\n🔐 MFA未設定ユーザー ({len(audit_results['users_without_mfa'])}):"
            for username in audit_results['users_without_mfa'][:5]:
                report += f"\n• {username}"
            if len(audit_results['users_without_mfa']) > 5:
                report += f"\n• ... 他{len(audit_results['users_without_mfa']) - 5}件"
        
        if key_audit_results.get('users_with_old_keys'):
            report += f"\n\n🔄 キー更新推奨ユーザー ({len(key_audit_results['users_with_old_keys'])}):"
            for key_info in key_audit_results['users_with_old_keys'][:5]:
                report += f"\n• {key_info['username']} (キー年齢: {key_info['age_days']}日)"
            if len(key_audit_results['users_with_old_keys']) > 5:
                report += f"\n• ... 他{len(key_audit_results['users_with_old_keys']) - 5}件"
        
        if audit_results.get('compliance_violations'):
            report += f"\n\n📋 コンプライアンス違反 ({len(audit_results['compliance_violations'])}):"
            for violation in audit_results['compliance_violations'][:3]:
                report += f"\n• {violation['username']}: {', '.join(violation['violations'][:2])}"
        
        report += f"\n\n💡 推奨アクション:"
        report += f"\n• 未使用ユーザーの無効化または削除"
        report += f"\n• 全ユーザーのMFA設定強制"
        report += f"\n• 古いアクセスキーのローテーション"
        report += f"\n• 権限の最小化（Principle of Least Privilege）"
        report += f"\n• 定期的なアクセスレビューの実施"
        
        return report
    
    def send_notification(self, report: str, is_critical: bool = False):
        """通知を送信"""
        try:
            subject = "🚨 ITSANDBOX IAM 緊急セキュリティアラート" if is_critical else "🔐 ITSANDBOX IAM セキュリティ監査レポート"
            
            # SNS通知
            if SNS_TOPIC_ARN:
                sns_client.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject=subject,
                    Message=report
                )
                logger.info("SNS通知を送信しました")
            
            # SES通知
            if NOTIFICATION_EMAIL:
                ses_client.send_email(
                    Source=NOTIFICATION_EMAIL,
                    Destination={'ToAddresses': [NOTIFICATION_EMAIL]},
                    Message={
                        'Subject': {'Data': subject},
                        'Body': {'Text': {'Data': report}}
                    }
                )
                logger.info("メール通知を送信しました")
            
        except Exception as e:
            logger.error(f"通知送信エラー: {str(e)}")

def lambda_handler(event, context):
    """Lambda エントリーポイント"""
    try:
        user_manager = ITSANDBOXUserManager()
        action = event.get('action', 'audit_users')
        
        if action == 'audit_users':
            # ユーザー監査実行
            audit_results = user_manager.audit_users()
            logger.info(f"ユーザー監査完了: {audit_results.get('total_users', 0)}人をチェック")
            
            # 結果を返す
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'User audit completed successfully',
                    'audit_results': audit_results
                })
            }
        
        elif action == 'audit_access_keys':
            # アクセスキー監査実行
            key_audit_results = user_manager.audit_access_keys()
            logger.info(f"アクセスキー監査完了: {key_audit_results.get('total_users_checked', 0)}人をチェック")
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Access key audit completed successfully',
                    'key_audit_results': key_audit_results
                })
            }
        
        elif action == 'full_audit':
            # 完全監査実行
            audit_results = user_manager.audit_users()
            key_audit_results = user_manager.audit_access_keys()
            
            # レポート生成
            report = user_manager.create_audit_report(audit_results, key_audit_results)
            
            # 緊急レベル判定
            critical_issues = (
                len(audit_results.get('users_with_excessive_permissions', [])) +
                len(audit_results.get('compliance_violations', []))
            )
            is_critical = critical_issues >= 3
            
            # 通知送信
            user_manager.send_notification(report, is_critical)
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Full audit completed successfully',
                    'audit_results': audit_results,
                    'key_audit_results': key_audit_results,
                    'is_critical': is_critical
                })
            }
        
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': f'Unknown action: {action}'
                })
            }
        
    except Exception as e:
        logger.error(f"Lambda実行エラー: {str(e)}")
        
        # エラー通知
        error_message = f"❌ ITSANDBOX IAM管理エラー\n\nエラー内容: {str(e)}\n時刻: {datetime.utcnow().isoformat()}"
        
        if SNS_TOPIC_ARN:
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="❌ ITSANDBOX IAM管理エラー",
                Message=error_message
            )
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'IAM management failed',
                'error': str(e)
            })
        }

# ローカルテスト用
if __name__ == "__main__":
    test_event = {"action": "full_audit"}
    test_context = {}
    result = lambda_handler(test_event, test_context)
    print(json.dumps(result, indent=2))