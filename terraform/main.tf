# ==============================================================================
# terraform/main.tf
# ==============================================================================
# AWS CloudOps & Cost Governance Automation
# Author: CloudOps Engineering (Reference Architecture)
# Standards: Free-Tier Compatible, Least-Privilege IAM, Event-Driven Automation
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ==============================================================================
# 1. NETWORKING (VPC, SUBNETS, ROUTE TABLES)
# ==============================================================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 2 Public Subnets (for NAT/Ingress if needed)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-2"
  }
}

# 2 Private Subnets (for EC2 & RDS)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.project_name}-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.project_name}-private-2"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# 2. SECURITY GROUPS (LEAST-PRIVILEGE ACCESS - ZERO 0.0.0.0/0 SSH)
# ==============================================================================
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for internal EC2 workloads"
  vpc_id      = aws_vpc.main.id

  # Ingress restricted to internal VPC CIDR only (No public SSH port 22 exposure!)
  ingress {
    description = "Allow internal HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Outbound to internet via SSM / HTTPS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for internal RDS database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow Postgres access from EC2 security group only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# ==============================================================================
# 3. IAM ROLE FOR EC2 (AWS SYSTEMS MANAGER - NO PUBLIC SSH KEYS NEEDED)
# ==============================================================================
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ==============================================================================
# 4. COMPUTE & DATABASE (EC2 & RDS FREE-TIER ELIGIBLE)
# ==============================================================================
resource "aws_instance" "app_server" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.public_1.id # Public subnet for simple testing, but access is SSM-only
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-dev-server"
  }
}

resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags = {
    Name = "${var.project_name}-rds-subnets"
  }
}

resource "aws_db_instance" "dev_db" {
  identifier             = "${var.project_name}-dev-db"
  allocated_storage      = 20
  max_allocated_storage  = 20
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = "15.7"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true # Ensures clean and instant terraform destroy!
  publicly_accessible    = false

  tags = {
    Name = "${var.project_name}-dev-database"
  }
}

# ==============================================================================
# 5. S3 BUCKET WITH FINOPS LIFECYCLE RULE (GLACIER TRANSITION)
# ==============================================================================
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket        = "${var.project_name}-data-lake-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Lifecycle Rule: Transition cold objects >90 days to Glacier Deep Archive (95% cost cut)
resource "aws_s3_bucket_lifecycle_configuration" "finops_lifecycle" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    id     = "archive-cold-data-to-glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 365
    }
  }
}

# ==============================================================================
# 6. INCIDENT OBSERVABILITY: CLOUDWATCH ALARMS & SNS NOTIFICATIONS
# ==============================================================================
resource "aws_sns_topic" "alerts_topic" {
  name = "${var.project_name}-incident-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm: High EC2 CPU (>80%)
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project_name}-EC2-CPU-Utilization-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers alert when EC2 CPU exceeds 80% for 2 consecutive periods"
  alarm_actions       = [aws_sns_topic.alerts_topic.arn]

  dimensions = {
    InstanceId = aws_instance.app_server.id
  }
}

# CloudWatch Alarm: Low RDS Free Storage (<5 GB)
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-RDS-Free-Storage-Space-Low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120 # 5 GB in bytes
  alarm_description   = "Triggers alert when RDS database storage drops below 5 GB"
  alarm_actions       = [aws_sns_topic.alerts_topic.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.dev_db.identifier
  }
}

# ==============================================================================
# 7. SERVERLESS COST GOVERNANCE: LAMBDA AUTO-SCHEDULER (START/STOP)
# ==============================================================================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/start_stop_scheduler.py"
  output_path = "${path.module}/start_stop_scheduler.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Least-privilege policy allowing only EC2/RDS Start/Stop and logging
resource "aws_iam_policy" "lambda_scheduler_policy" {
  name = "${var.project_name}-scheduler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "rds:DescribeDBInstances",
          "rds:StopDBInstance",
          "rds:StartDBInstance",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_scheduler_policy.arn
}

resource "aws_lambda_function" "cost_scheduler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-instance-scheduler"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "start_stop_scheduler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TAG_KEY   = "Environment"
      TAG_VALUE = var.environment
    }
  }
}

# EventBridge Rule 1: Auto-STOP instances at 19:00 Mon-Fri (12:00 UTC)
resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "${var.project_name}-stop-evening-schedule"
  description         = "Triggers Lambda to stop non-prod instances at 19:00 Bangkok time (12:00 UTC)"
  schedule_expression = "cron(0 12 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_schedule.name
  target_id = "TriggerLambdaStop"
  arn       = aws_lambda_function.cost_scheduler.arn
  input     = jsonencode({ action = "stop" })
}

resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule.arn
}

# EventBridge Rule 2: Auto-START instances at 08:00 Mon-Fri (01:00 UTC)
resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "${var.project_name}-start-morning-schedule"
  description         = "Triggers Lambda to start non-prod instances at 08:00 Bangkok time (01:00 UTC)"
  schedule_expression = "cron(0 1 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_schedule.name
  target_id = "TriggerLambdaStart"
  arn       = aws_lambda_function.cost_scheduler.arn
  input     = jsonencode({ action = "start" })
}

resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule.arn
}
