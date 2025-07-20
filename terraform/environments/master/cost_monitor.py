import json
import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal

def handler(event, context):
    """
    ITSANDBOX Cost Monitor Lambda Function
    Monitors daily AWS costs and sends alerts when thresholds are exceeded
    """
    
    # Initialize AWS clients
    ce_client = boto3.client('ce')
    sns_client = boto3.client('sns')
    
    # Get environment variables
    budget_limit = float(os.environ.get('BUDGET_LIMIT', '100'))
    admin_email = os.environ.get('ADMIN_EMAIL', 'hoseiitsandbox@gmail.com')
    
    try:
        # Calculate date range (yesterday to today)
        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=1)
        
        # Get cost and usage data
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['BlendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )
        
        # Calculate total cost
        total_cost = 0
        service_costs = []
        
        for result in response['ResultsByTime']:
            for group in result['Groups']:
                service_name = group['Keys'][0]
                cost = float(group['Metrics']['BlendedCost']['Amount'])
                if cost > 0:
                    total_cost += cost
                    service_costs.append({
                        'service': service_name,
                        'cost': cost
                    })
        
        # Get monthly cost (current month)
        start_of_month = end_date.replace(day=1)
        monthly_response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_of_month.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='MONTHLY',
            Metrics=['BlendedCost']
        )
        
        monthly_cost = 0
        if monthly_response['ResultsByTime']:
            monthly_cost = float(monthly_response['ResultsByTime'][0]['Total']['BlendedCost']['Amount'])
        
        # Calculate usage percentage
        usage_percentage = (monthly_cost / budget_limit) * 100
        
        # Prepare cost report
        cost_report = {
            'date': end_date.strftime('%Y-%m-%d'),
            'daily_cost': total_cost,
            'monthly_cost': monthly_cost,
            'budget_limit': budget_limit,
            'usage_percentage': usage_percentage,
            'service_costs': sorted(service_costs, key=lambda x: x['cost'], reverse=True)[:10]
        }
        
        # Log cost information
        print(f"ITSANDBOX Cost Report for {end_date}")
        print(f"Daily Cost: ${total_cost:.2f}")
        print(f"Monthly Cost: ${monthly_cost:.2f}")
        print(f"Budget Usage: {usage_percentage:.1f}%")
        
        # Send alert if threshold exceeded
        alert_sent = False
        if usage_percentage >= 90:
            send_alert(sns_client, cost_report, 'CRITICAL', admin_email)
            alert_sent = True
        elif usage_percentage >= 80:
            send_alert(sns_client, cost_report, 'WARNING', admin_email)
            alert_sent = True
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cost monitoring completed successfully',
                'cost_report': cost_report,
                'alert_sent': alert_sent
            }, default=str)
        }
        
    except Exception as e:
        error_message = f"Error in cost monitoring: {str(e)}"
        print(error_message)
        
        # Send error notification
        try:
            sns_client.publish(
                TopicArn=get_sns_topic_arn(),
                Subject='ITSANDBOX Cost Monitor Error',
                Message=f"Cost monitoring failed: {error_message}"
            )
        except:
            pass
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_message
            })
        }

def send_alert(sns_client, cost_report, alert_type, admin_email):
    """Send cost alert via SNS"""
    
    if alert_type == 'CRITICAL':
        subject = f"🚨 ITSANDBOX CRITICAL: Budget 90% Exceeded - ${cost_report['monthly_cost']:.2f}"
        message_header = "CRITICAL BUDGET ALERT"
        emoji = "🚨"
    else:
        subject = f"⚠️ ITSANDBOX WARNING: Budget 80% Exceeded - ${cost_report['monthly_cost']:.2f}"
        message_header = "BUDGET WARNING"
        emoji = "⚠️"
    
    # Create detailed message
    message = f"""
{emoji} {message_header} {emoji}

ITSANDBOX Budget Alert - {cost_report['date']}

📊 COST SUMMARY:
• Daily Cost: ${cost_report['daily_cost']:.2f}
• Monthly Cost: ${cost_report['monthly_cost']:.2f}
• Budget Limit: ${cost_report['budget_limit']:.2f}
• Usage: {cost_report['usage_percentage']:.1f}%

💰 TOP SERVICES:
"""
    
    for i, service in enumerate(cost_report['service_costs'][:5], 1):
        message += f"{i}. {service['service']}: ${service['cost']:.2f}\n"
    
    message += f"""
🔗 QUICK LINKS:
• AWS Cost Explorer: https://console.aws.amazon.com/cost-management/home
• ITSANDBOX Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards

📧 Sent to: {admin_email}
🤖 Generated by ITSANDBOX Cost Monitor
"""
    
    try:
        # Try to get SNS topic ARN from existing topics
        sns_topic_arn = get_sns_topic_arn()
        
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message
        )
        print(f"Alert sent successfully: {alert_type}")
        
    except Exception as e:
        print(f"Failed to send SNS alert: {str(e)}")
        # Fallback: just log the alert
        print(f"ALERT CONTENT:\nSubject: {subject}\nMessage: {message}")

def get_sns_topic_arn():
    """Get SNS topic ARN for cost alerts"""
    sns_client = boto3.client('sns')
    
    try:
        response = sns_client.list_topics()
        for topic in response['Topics']:
            if 'itsandbox-cost-alerts' in topic['TopicArn']:
                return topic['TopicArn']
    except Exception as e:
        print(f"Error finding SNS topic: {str(e)}")
    
    # Fallback: construct ARN based on current account
    sts_client = boto3.client('sts')
    account_id = sts_client.get_caller_identity()['Account']
    region = boto3.Session().region_name or 'us-east-1'
    
    return f"arn:aws:sns:{region}:{account_id}:itsandbox-cost-alerts"