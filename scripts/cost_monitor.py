"""
ITSANDBOX Cost Monitoring Lambda Function
Monitors AWS costs and sends alerts when thresholds are exceeded
"""

import json
import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal


def handler(event, context):
    """
    Lambda handler for cost monitoring
    """
    
    # Initialize AWS clients
    ce_client = boto3.client('ce')
    budgets_client = boto3.client('budgets')
    sns_client = boto3.client('sns')
    
    # Get environment variables
    budget_limit = float(os.environ.get('BUDGET_LIMIT', '100'))
    admin_email = os.environ.get('ADMIN_EMAIL', 'hoseiitsandbox@gmail.com')
    
    try:
        # Get current month's cost
        current_cost = get_current_month_cost(ce_client)
        
        # Get cost by service
        cost_by_service = get_cost_by_service(ce_client)
        
        # Get cost by project
        cost_by_project = get_cost_by_project(ce_client)
        
        # Calculate percentage used
        percentage_used = (current_cost / budget_limit) * 100
        
        # Generate cost report
        report = generate_cost_report(
            current_cost,
            budget_limit,
            percentage_used,
            cost_by_service,
            cost_by_project
        )
        
        # Send alert if threshold exceeded
        if percentage_used > 80:
            send_cost_alert(
                sns_client,
                current_cost,
                budget_limit,
                percentage_used,
                report
            )
        
        # Stop non-essential resources if over 90%
        if percentage_used > 90:
            stop_non_essential_resources()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cost monitoring completed successfully',
                'currentCost': current_cost,
                'budgetLimit': budget_limit,
                'percentageUsed': percentage_used,
                'report': report
            })
        }
        
    except Exception as e:
        print(f"Error in cost monitoring: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }


def get_current_month_cost(ce_client):
    """
    Get current month's cost from Cost Explorer
    """
    
    # Get current month date range
    end_date = datetime.now().date()
    start_date = end_date.replace(day=1)
    
    response = ce_client.get_cost_and_usage(
        TimePeriod={
            'Start': start_date.strftime('%Y-%m-%d'),
            'End': end_date.strftime('%Y-%m-%d')
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )
    
    total_cost = 0
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            amount = float(group['Metrics']['UnblendedCost']['Amount'])
            total_cost += amount
    
    return total_cost


def get_cost_by_service(ce_client):
    """
    Get cost breakdown by AWS service
    """
    
    end_date = datetime.now().date()
    start_date = end_date.replace(day=1)
    
    response = ce_client.get_cost_and_usage(
        TimePeriod={
            'Start': start_date.strftime('%Y-%m-%d'),
            'End': end_date.strftime('%Y-%m-%d')
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )
    
    cost_by_service = {}
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service = group['Keys'][0]
            amount = float(group['Metrics']['UnblendedCost']['Amount'])
            if amount > 0:
                cost_by_service[service] = amount
    
    return cost_by_service


def get_cost_by_project(ce_client):
    """
    Get cost breakdown by project (using tags)
    """
    
    end_date = datetime.now().date()
    start_date = end_date.replace(day=1)
    
    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'TAG',
                    'Key': 'Project'
                }
            ]
        )
        
        cost_by_project = {}
        for result in response['ResultsByTime']:
            for group in result['Groups']:
                project = group['Keys'][0] if group['Keys'][0] else 'Untagged'
                amount = float(group['Metrics']['UnblendedCost']['Amount'])
                if amount > 0:
                    cost_by_project[project] = amount
        
        return cost_by_project
        
    except Exception as e:
        print(f"Error getting cost by project: {str(e)}")
        return {}


def generate_cost_report(current_cost, budget_limit, percentage_used, cost_by_service, cost_by_project):
    """
    Generate detailed cost report
    """
    
    report = {
        'summary': {
            'current_cost': current_cost,
            'budget_limit': budget_limit,
            'percentage_used': percentage_used,
            'remaining_budget': budget_limit - current_cost
        },
        'cost_by_service': cost_by_service,
        'cost_by_project': cost_by_project,
        'top_services': sorted(cost_by_service.items(), key=lambda x: x[1], reverse=True)[:5],
        'recommendations': generate_recommendations(current_cost, budget_limit, cost_by_service)
    }
    
    return report


def generate_recommendations(current_cost, budget_limit, cost_by_service):
    """
    Generate cost optimization recommendations
    """
    
    recommendations = []
    
    # Check if approaching budget limit
    if current_cost / budget_limit > 0.8:
        recommendations.append("🚨 Budget warning: You're using over 80% of your monthly budget")
    
    # Check for high-cost services
    for service, cost in cost_by_service.items():
        if cost > budget_limit * 0.3:  # More than 30% of budget
            recommendations.append(f"💡 {service} is consuming {cost:.2f} USD ({cost/budget_limit*100:.1f}% of budget)")
    
    # General recommendations
    recommendations.extend([
        "🔧 Consider using Lambda instead of EC2 for compute tasks",
        "📊 Use S3 Intelligent Tiering for storage cost optimization",
        "⏰ Schedule EC2 instances to run only during business hours",
        "🗑️ Clean up unused resources regularly"
    ])
    
    return recommendations


def send_cost_alert(sns_client, current_cost, budget_limit, percentage_used, report):
    """
    Send cost alert via SNS
    """
    
    subject = f"🚨 ITSANDBOX Cost Alert: {percentage_used:.1f}% of budget used"
    
    message = f"""
ITSANDBOX Cost Alert

Current Status:
- Current Cost: ${current_cost:.2f}
- Budget Limit: ${budget_limit:.2f}
- Percentage Used: {percentage_used:.1f}%
- Remaining Budget: ${budget_limit - current_cost:.2f}

Top Services by Cost:
"""
    
    for service, cost in report['top_services']:
        message += f"- {service}: ${cost:.2f}\n"
    
    message += "\nRecommendations:\n"
    for rec in report['recommendations'][:3]:
        message += f"- {rec}\n"
    
    message += f"\nDashboard: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=ITSANDBOX-Cost-Dashboard"
    
    # Get SNS topic ARN from environment or construct it
    account_id = boto3.client('sts').get_caller_identity()['Account']
    topic_arn = f"arn:aws:sns:us-east-1:{account_id}:itsandbox-cost-alerts"
    
    try:
        sns_client.publish(
            TopicArn=topic_arn,
            Subject=subject,
            Message=message
        )
        print("Cost alert sent successfully")
    except Exception as e:
        print(f"Error sending cost alert: {str(e)}")


def stop_non_essential_resources():
    """
    Stop non-essential resources when budget is exceeded
    """
    
    ec2_client = boto3.client('ec2')
    
    try:
        # Stop EC2 instances tagged as non-essential
        response = ec2_client.describe_instances(
            Filters=[
                {
                    'Name': 'tag:Essential',
                    'Values': ['false', 'no']
                },
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
        
        instances_to_stop = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instances_to_stop.append(instance['InstanceId'])
        
        if instances_to_stop:
            ec2_client.stop_instances(InstanceIds=instances_to_stop)
            print(f"Stopped {len(instances_to_stop)} non-essential instances")
        
    except Exception as e:
        print(f"Error stopping non-essential resources: {str(e)}")


if __name__ == "__main__":
    # For local testing
    test_event = {}
    test_context = {}
    
    result = handler(test_event, test_context)
    print(json.dumps(result, indent=2))