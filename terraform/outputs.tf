# ==============================================================================
# terraform/outputs.tf
# ==============================================================================
# Outputs for verification and operational runbooks
# ==============================================================================

output "vpc_id" {
  description = "ID of the deployed VPC"
  value       = aws_vpc.main.id
}

output "ec2_instance_id" {
  description = "Target EC2 instance managed by cost scheduler"
  value       = aws_instance.app_server.id
}

output "rds_endpoint" {
  description = "Endpoint address of the RDS PostgreSQL instance"
  value       = aws_db_instance.dev_db.endpoint
}

output "s3_data_lake_bucket" {
  description = "S3 bucket with 90-day Glacier lifecycle policy"
  value       = aws_s3_bucket.logs_bucket.bucket
}

output "cloudwatch_alarm_ec2_cpu" {
  description = "CloudWatch Alarm monitoring EC2 CPU utilization"
  value       = aws_cloudwatch_metric_alarm.ec2_cpu_high.arn
}

output "cloudwatch_alarm_rds_storage" {
  description = "CloudWatch Alarm monitoring RDS free storage space"
  value       = aws_cloudwatch_metric_alarm.rds_storage_low.arn
}

output "lambda_scheduler_arn" {
  description = "ARN of the automated Start/Stop Lambda function"
  value       = aws_lambda_function.cost_scheduler.arn
}

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN receiving incident notifications"
  value       = aws_sns_topic.alerts_topic.arn
}
