# ==============================================================================
# terraform/variables.tf
# ==============================================================================
# Input variables for CloudOps & Cost Governance Suite
# ==============================================================================

variable "aws_region" {
  description = "AWS region for all deployed resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name tag for resource naming and cost allocation"
  type        = string
  default     = "cloudops-governance"
}

variable "environment" {
  description = "Target environment for auto-start/stop scheduling"
  type        = string
  default     = "Dev"
}

variable "alert_email" {
  description = "Notification email address for CloudWatch incident alerts"
  type        = string
  default     = "admin@example.com"
}

variable "db_username" {
  description = "Master username for RDS Postgres instance"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password for RDS Postgres instance (min 8 chars)"
  type        = string
  sensitive   = true
  default     = "CloudOpsPass2026!"
}
