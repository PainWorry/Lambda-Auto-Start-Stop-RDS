#!/usr/bin/env python3
"""
lambda/start_stop_scheduler.py
=============================================================================
AWS Lambda Function: Automated EC2 & RDS Instance Scheduler
Author: CloudOps Engineering (Reference Architecture)
Objective: Cost Governance & Cloud FinOps Automation
- Shuts down Non-Production (Dev/Test) EC2 & RDS instances outside business hours
  (e.g., Weekday evenings 19:00 and weekends).
- Automatically restarts instances before business hours (08:00 Mon-Fri).
- Estimated Cost Reduction: ~65% reduction in non-prod compute & database spend.
=============================================================================
"""

import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2_client = boto3.client('ec2')
rds_client = boto3.client('rds')

TARGET_TAG_KEY = os.environ.get('TAG_KEY', 'Environment')
TARGET_TAG_VALUE = os.environ.get('TAG_VALUE', 'Dev')

def get_target_ec2_instances():
    """Finds all EC2 instances matching the target environment tag."""
    filters = [
        {'Name': f'tag:{TARGET_TAG_KEY}', 'Values': [TARGET_TAG_VALUE]},
        {'Name': 'instance-state-name', 'Values': ['running', 'stopped']}
    ]
    response = ec2_client.describe_instances(Filters=filters)
    instance_ids = []
    for reservation in response.get('Reservations', []):
        for instance in reservation.get('Instances', []):
            instance_ids.append(instance['InstanceId'])
    return instance_ids

def get_target_rds_instances():
    """Finds all RDS instances matching the target environment tag."""
    response = rds_client.describe_db_instances()
    target_dbs = []
    for db in response.get('DBInstances', []):
        db_arn = db['DBInstanceArn']
        tags_resp = rds_client.list_tags_for_resource(ResourceName=db_arn)
        tags = {t['Key']: t['Value'] for t in tags_resp.get('TagList', [])}
        if tags.get(TARGET_TAG_KEY) == TARGET_TAG_VALUE:
            target_dbs.append({
                'id': db['DBInstanceIdentifier'],
                'status': db['DBInstanceStatus']
            })
    return target_dbs

def lambda_handler(event, context):
    """
    Main Lambda handler triggered by EventBridge cron schedule or manual invocation.
    Expected event payload:
    {"action": "stop"} or {"action": "start"}
    """
    action = event.get('action', 'stop').lower()
    logger.info(f"=== Starting CloudOps Scheduler: ACTION = {action.upper()} ===")

    ec2_ids = get_target_ec2_instances()
    rds_dbs = get_target_rds_instances()

    results = {
        'action': action,
        'ec2': {},
        'rds': {}
    }

    # 1. Manage EC2 Instances
    if ec2_ids:
        if action == 'stop':
            logger.info(f"Stopping EC2 instances: {ec2_ids}")
            resp = ec2_client.stop_instances(InstanceIds=ec2_ids)
            results['ec2']['stopped'] = ec2_ids
        elif action == 'start':
            logger.info(f"Starting EC2 instances: {ec2_ids}")
            resp = ec2_client.start_instances(InstanceIds=ec2_ids)
            results['ec2']['started'] = ec2_ids
    else:
        logger.info("No matching EC2 instances found.")
        results['ec2']['message'] = "No instances found"

    # 2. Manage RDS DB Instances
    for db in rds_dbs:
        db_id = db['id']
        status = db['status']
        if action == 'stop':
            if status == 'available':
                logger.info(f"Stopping RDS instance: {db_id}")
                rds_client.stop_db_instance(DBInstanceIdentifier=db_id)
                results['rds'][db_id] = "Stop initiated"
            else:
                logger.info(f"Skipping RDS {db_id}: current status is '{status}'")
                results['rds'][db_id] = f"Skipped (status: {status})"
        elif action == 'start':
            if status == 'stopped':
                logger.info(f"Starting RDS instance: {db_id}")
                rds_client.start_db_instance(DBInstanceIdentifier=db_id)
                results['rds'][db_id] = "Start initiated"
            else:
                logger.info(f"Skipping RDS {db_id}: current status is '{status}'")
                results['rds'][db_id] = f"Skipped (status: {status})"

    logger.info(f"=== Execution Summary: {results} ===")
    return {
        'statusCode': 200,
        'body': results
    }
