import boto3
import os
import logging
import json

route53_client = boto3.client('route53')
ec2_client = boto3.client('ec2')

# Environment variables
HOSTED_ZONE_ID = os.getenv('HOSTED_ZONE_ID')
PLACEHOLDER_IP = "0.0.0.0"  # Placeholder when no active IPs
instance_name_to_dns = json.loads(os.getenv('INSTANCE_TO_DNS', '{}'))

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    detail = event.get('detail', {})
    instance_id = detail.get('instance-id')
    state = detail.get('state')

    if not instance_id or not state:
        logger.error("Missing required fields in event detail.")
        return

    if state in ['running', 'shutting-down']:
        instance_name, private_ip = get_instance_details(instance_id)

        if instance_name in instance_name_to_dns:
            dns_name = instance_name_to_dns[instance_name]
            if state == 'running' and private_ip:
                update_route53_record(dns_name, private_ip, action="ADD")
            elif state == 'shutting-down':
                update_route53_record(dns_name, private_ip, action="REMOVE")
        else:
            logger.info(f"Instance {instance_id} with name {instance_name} not in DNS mapping.")

def get_instance_details(instance_id):
    try:
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        instance_name = next(
            (tag['Value'] for tag in instance.get('Tags', []) if tag['Key'] == 'Name'),
            None
        )
        private_ip = instance.get('PrivateIpAddress')
        return instance_name, private_ip
    except Exception as e:
        logger.error(f"Error getting details for instance {instance_id}: {e}")
        return None, None

def update_route53_record(dns_name, ip_address, action):
    try:
        current_records = route53_client.list_resource_record_sets(
            HostedZoneId=HOSTED_ZONE_ID,
            StartRecordName=dns_name,
            StartRecordType="A",
            MaxItems="1"
        )

        resource_records = []
        if current_records['ResourceRecordSets']:
            record_set = current_records['ResourceRecordSets'][0]
            resource_records = [r['Value'] for r in record_set['ResourceRecords']]

        if action == "ADD":
            if PLACEHOLDER_IP in resource_records:
                resource_records.remove(PLACEHOLDER_IP)
            if ip_address not in resource_records:
                resource_records.append(ip_address)
        elif action == "REMOVE":
            if ip_address in resource_records:
                resource_records.remove(ip_address)

        if not resource_records:
            resource_records = [PLACEHOLDER_IP]

        change_batch = {
            'Changes': [{
                'Action': "UPSERT",
                'ResourceRecordSet': {
                    'Name': dns_name,
                    'Type': 'A',
                    'TTL': 60,
                    'ResourceRecords': [{'Value': ip} for ip in resource_records],
                },
            }],
        }

        route53_client.change_resource_record_sets(
            HostedZoneId=HOSTED_ZONE_ID,
            ChangeBatch=change_batch
        )
        logger.info(f"Updated DNS record {dns_name} with IPs: {resource_records}")
    except Exception as e:
        logger.error(f"Error updating DNS record {dns_name}: {e}")