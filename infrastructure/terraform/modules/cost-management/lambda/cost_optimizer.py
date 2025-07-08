"""
ITSANDBOX Cost Optimizer Lambda Function
月額$100予算の効率的管理と自動最適化
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
ce_client = boto3.client('ce')
ec2_client = boto3.client('ec2')
rds_client = boto3.client('rds')
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
budgets_client = boto3.client('budgets')

# 環境変数
ORGANIZATION_BUDGET = float(os.environ.get('ORGANIZATION_BUDGET', '100'))
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL', '')

class ITSANDBOXCostOptimizer:
    def __init__(self):
        self.organization_budget = ORGANIZATION_BUDGET
        self.current_date = datetime.utcnow()
        self.month_start = self.current_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
    def get_current_month_costs(self) -> Dict[str, Any]:
        """今月の累計コストを取得"""
        try:
            response = ce_client.get_cost_and_usage(
                TimePeriod={
                    'Start': self.month_start.strftime('%Y-%m-%d'),
                    'End': self.current_date.strftime('%Y-%m-%d')
                },
                Granularity='MONTHLY',
                Metrics=['BlendedCost'],
                GroupBy=[
                    {'Type': 'DIMENSION', 'Key': 'SERVICE'},
                    {'Type': 'TAG', 'Key': 'Project'}
                ]
            )
            
            total_cost = 0
            service_costs = {}
            project_costs = {}
            
            for result in response['ResultsByTime']:
                for group in result['Groups']:
                    cost = float(group['Metrics']['BlendedCost']['Amount'])
                    total_cost += cost
                    
                    # サービス別コスト
                    service_name = group['Keys'][0] if group['Keys'] else 'Unknown'
                    service_costs[service_name] = service_costs.get(service_name, 0) + cost
                    
                    # プロジェクト別コスト
                    project_name = group['Keys'][1] if len(group['Keys']) > 1 else 'Untagged'
                    project_costs[project_name] = project_costs.get(project_name, 0) + cost
            
            return {
                'total_cost': total_cost,
                'service_costs': service_costs,
                'project_costs': project_costs,
                'budget_usage_percentage': (total_cost / self.organization_budget) * 100
            }
            
        except Exception as e:
            logger.error(f"コスト取得エラー: {str(e)}")
            return {'total_cost': 0, 'service_costs': {}, 'project_costs': {}, 'budget_usage_percentage': 0}
    
    def analyze_unused_resources(self) -> Dict[str, List[str]]:
        """未使用リソースの分析"""
        unused_resources = {
            'ec2_instances': [],
            'ebs_snapshots': [],
            'elastic_ips': [],
            'rds_instances': []
        }
        
        try:
            # 停止中のEC2インスタンス
            ec2_response = ec2_client.describe_instances(
                Filters=[{'Name': 'instance-state-name', 'Values': ['stopped']}]
            )
            
            for reservation in ec2_response['Reservations']:
                for instance in reservation['Instances']:
                    # 7日以上停止中のインスタンス
                    if instance['State']['Name'] == 'stopped':
                        state_transition_time = instance['StateTransitionReason']
                        if '7 days ago' in state_transition_time or 'weeks ago' in state_transition_time:
                            unused_resources['ec2_instances'].append({
                                'InstanceId': instance['InstanceId'],
                                'InstanceType': instance['InstanceType'],
                                'StoppedTime': state_transition_time
                            })
            
            # 古いEBSスナップショット（30日以上）
            snapshots_response = ec2_client.describe_snapshots(OwnerIds=['self'])
            cutoff_date = self.current_date - timedelta(days=30)
            
            for snapshot in snapshots_response['Snapshots']:
                if snapshot['StartTime'].replace(tzinfo=None) < cutoff_date:
                    unused_resources['ebs_snapshots'].append({
                        'SnapshotId': snapshot['SnapshotId'],
                        'Size': snapshot['VolumeSize'],
                        'StartTime': snapshot['StartTime'].isoformat()
                    })
            
            # 未使用のElastic IP
            eip_response = ec2_client.describe_addresses()
            for address in eip_response['Addresses']:
                if 'InstanceId' not in address:  # アタッチされていないEIP
                    unused_resources['elastic_ips'].append({
                        'AllocationId': address['AllocationId'],
                        'PublicIp': address['PublicIp']
                    })
            
            # 停止中のRDSインスタンス
            rds_response = rds_client.describe_db_instances()
            for db_instance in rds_response['DBInstances']:
                if db_instance['DBInstanceStatus'] == 'stopped':
                    unused_resources['rds_instances'].append({
                        'DBInstanceIdentifier': db_instance['DBInstanceIdentifier'],
                        'DBInstanceClass': db_instance['DBInstanceClass'],
                        'Engine': db_instance['Engine']
                    })
                    
        except Exception as e:
            logger.error(f"未使用リソース分析エラー: {str(e)}")
        
        return unused_resources
    
    def get_cost_recommendations(self, costs: Dict[str, Any]) -> List[str]:
        """コスト最適化の推奨事項を生成"""
        recommendations = []
        
        # 予算使用率に基づく推奨
        usage_percentage = costs['budget_usage_percentage']
        
        if usage_percentage > 80:
            recommendations.append("🚨 予算使用率が80%を超えています。緊急にコスト削減が必要です。")
            recommendations.append("• 不要なリソースの即座停止・削除を検討してください")
            recommendations.append("• 新規リソース作成を一時停止することを推奨します")
        elif usage_percentage > 60:
            recommendations.append("⚠️ 予算使用率が60%を超えています。コスト監視を強化してください。")
            recommendations.append("• 未使用リソースの定期的な確認を実施してください")
        
        # サービス別コスト分析
        service_costs = costs['service_costs']
        top_services = sorted(service_costs.items(), key=lambda x: x[1], reverse=True)[:3]
        
        if top_services:
            recommendations.append("\n💰 主要なコスト要因:")
            for service, cost in top_services:
                percentage = (cost / costs['total_cost']) * 100
                recommendations.append(f"• {service}: ${cost:.2f} ({percentage:.1f}%)")
        
        # 具体的な最適化提案
        if 'Amazon Elastic Compute Cloud' in service_costs:
            recommendations.append("\n🖥️ EC2最適化提案:")
            recommendations.append("• インスタンスサイズの見直し（t3.micro → t3.nano）")
            recommendations.append("• 夜間・週末の自動停止設定")
            recommendations.append("• Reserved Instancesの検討（長期利用の場合）")
        
        if 'Amazon Simple Storage Service' in service_costs:
            recommendations.append("\n📦 S3最適化提案:")
            recommendations.append("• ライフサイクルポリシーの設定（IA → Glacier）")
            recommendations.append("• 重複ファイルの削除")
            recommendations.append("• 不要な古いバックアップの削除")
        
        return recommendations
    
    def create_cost_report(self, costs: Dict[str, Any], unused_resources: Dict[str, List], recommendations: List[str]) -> str:
        """コストレポートを生成"""
        report = f"""
📊 ITSANDBOX 日次コストレポート
日付: {self.current_date.strftime('%Y-%m-%d %H:%M UTC')}

💰 今月のコスト状況:
• 累計コスト: ${costs['total_cost']:.2f}
• 予算: ${self.organization_budget:.2f}
• 使用率: {costs['budget_usage_percentage']:.1f}%
• 残り予算: ${self.organization_budget - costs['total_cost']:.2f}

📈 サービス別コスト (Top 5):
"""
        
        service_costs = costs['service_costs']
        top_services = sorted(service_costs.items(), key=lambda x: x[1], reverse=True)[:5]
        
        for service, cost in top_services:
            percentage = (cost / costs['total_cost']) * 100 if costs['total_cost'] > 0 else 0
            report += f"• {service}: ${cost:.2f} ({percentage:.1f}%)\n"
        
        report += f"\n🗂️ プロジェクト別コスト:\n"
        project_costs = costs['project_costs']
        for project, cost in sorted(project_costs.items(), key=lambda x: x[1], reverse=True):
            percentage = (cost / costs['total_cost']) * 100 if costs['total_cost'] > 0 else 0
            report += f"• {project}: ${cost:.2f} ({percentage:.1f}%)\n"
        
        # 未使用リソース情報
        report += f"\n🔍 未使用リソース検出:\n"
        if unused_resources['ec2_instances']:
            report += f"• 停止中EC2インスタンス: {len(unused_resources['ec2_instances'])}台\n"
        if unused_resources['ebs_snapshots']:
            report += f"• 古いEBSスナップショット: {len(unused_resources['ebs_snapshots'])}個\n"
        if unused_resources['elastic_ips']:
            report += f"• 未使用Elastic IP: {len(unused_resources['elastic_ips'])}個\n"
        if unused_resources['rds_instances']:
            report += f"• 停止中RDSインスタンス: {len(unused_resources['rds_instances'])}台\n"
        
        # 推奨事項
        if recommendations:
            report += f"\n💡 推奨事項:\n"
            for rec in recommendations:
                report += f"{rec}\n"
        
        return report
    
    def send_notification(self, report: str, is_critical: bool = False):
        """通知の送信"""
        try:
            subject = "🚨 ITSANDBOX 緊急コストアラート" if is_critical else "📊 ITSANDBOX 日次コストレポート"
            
            # SNS通知
            if SNS_TOPIC_ARN:
                sns_client.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject=subject,
                    Message=report
                )
                logger.info("SNS通知を送信しました")
            
            # Slack通知（設定されている場合）
            if SLACK_WEBHOOK_URL:
                import urllib3
                import json
                
                http = urllib3.PoolManager()
                
                slack_message = {
                    "text": subject,
                    "blocks": [
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": f"```{report}```"
                            }
                        }
                    ]
                }
                
                response = http.request(
                    'POST',
                    SLACK_WEBHOOK_URL,
                    body=json.dumps(slack_message),
                    headers={'Content-Type': 'application/json'}
                )
                logger.info(f"Slack通知を送信しました: {response.status}")
                
        except Exception as e:
            logger.error(f"通知送信エラー: {str(e)}")

def lambda_handler(event, context):
    """Lambda エントリーポイント"""
    try:
        optimizer = ITSANDBOXCostOptimizer()
        
        # コスト分析
        costs = optimizer.get_current_month_costs()
        logger.info(f"現在のコスト: ${costs['total_cost']:.2f} ({costs['budget_usage_percentage']:.1f}%)")
        
        # 未使用リソース分析
        unused_resources = optimizer.analyze_unused_resources()
        
        # 推奨事項生成
        recommendations = optimizer.get_cost_recommendations(costs)
        
        # レポート生成
        report = optimizer.create_cost_report(costs, unused_resources, recommendations)
        
        # 緊急レベルの判定
        is_critical = costs['budget_usage_percentage'] >= 85
        
        # 通知送信
        optimizer.send_notification(report, is_critical)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cost analysis completed successfully',
                'total_cost': costs['total_cost'],
                'budget_usage_percentage': costs['budget_usage_percentage'],
                'is_critical': is_critical
            })
        }
        
    except Exception as e:
        logger.error(f"Lambda実行エラー: {str(e)}")
        
        # エラー通知
        error_message = f"❌ ITSANDBOX コスト分析エラー\n\nエラー内容: {str(e)}\n時刻: {datetime.utcnow().isoformat()}"
        
        if SNS_TOPIC_ARN:
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="❌ ITSANDBOX コスト分析エラー",
                Message=error_message
            )
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Cost analysis failed',
                'error': str(e)
            })
        }

# ローカルテスト用
if __name__ == "__main__":
    test_event = {}
    test_context = {}
    result = lambda_handler(test_event, test_context)
    print(json.dumps(result, indent=2))