# AWS CloudOps & Cost Governance Automation Suite
## Infrastructure Deployment and Operational Verification Report

* **Author:** Herren Karsemsak (Cloud & FinOps Engineer)
* **Project Repository:** `cloudops-cost-governance`
* **Target Cloud Provider:** Amazon Web Services (AWS)
* **Region:** Asia Pacific (Singapore) `ap-southeast-1`
* **Date:** October 11, 2026
* **Status:** Fully Deployed & Operationally Verified (35/35 Resources)

---

## 1. Executive Summary

This report documents the end-to-end deployment, security validation, and operational testing of the **AWS CloudOps & Cost Governance Automation Suite**. 

The infrastructure was provisioned deterministically using **Terraform (Infrastructure as Code)** into the AWS Singapore region (`ap-southeast-1`). All 35 cloud resources were verified against enterprise security benchmarks and AWS Well-Architected Framework principles.

### Key Operational Achievements
1. **Automated Non-Production Scheduling (FinOps):** Implemented an event-driven serverless scheduler (AWS EventBridge + Python 3.12 Lambda) that reduces non-production compute and database runtime from 168 hours/week to 55 hours/week, delivering a **67.3% cost reduction**.
2. **Zero-Trust Network Isolation:** Closed public SSH Port 22 entirely. EC2 instances are managed securely via **AWS Systems Manager (SSM Session Manager)**. The PostgreSQL database is placed in private subnets with **Security Group Chaining** accepting ingress only from the application server.
3. **Proactive Observability:** Configured Amazon CloudWatch metric alarms for EC2 CPU utilization (>80%) and RDS free storage space (<5 GB) linked directly to Amazon SNS email notifications.
4. **Storage Tiering Optimization:** Enforced S3 Lifecycle rules transitioning objects older than 90 days to **Amazon S3 Glacier Deep Archive**, cutting cold storage costs by 95%.
5. **Multi-Service FinOps Auditing:** Executed a custom Bash audit script validating EBS volume attachment, instance running states, S3 lifecycle policies, and open security group rules.

---

## 2. Infrastructure Architecture Overview

The deployed infrastructure comprises 35 resources organized into five functional layers:

| Architectural Layer | Core AWS Services | Quantity | Key Specifications |
| :--- | :--- | :---: | :--- |
| **Networking & Perimeter** | VPC, Subnets, IGW, Route Tables | 15 | CIDR `10.0.0.0/16`, Multi-AZ (`ap-southeast-1a`, `ap-southeast-1b`), Public/Private segregation |
| **Compute & Database** | EC2, RDS PostgreSQL, DB Subnet Group | 3 | EC2 `t3.micro` (Amazon Linux 2023), RDS `db.t3.micro` (PostgreSQL 15.13, 20 GB gp3) |
| **FinOps Automation** | EventBridge Rules, Lambda, IAM Role | 7 | Python 3.12 runtime, 08:00 Start / 19:00 Stop cron expressions, Tag-based resource discovery |
| **Data Lake & Lifecycle** | S3 Bucket, Lifecycle Configuration, Random ID | 4 | Private bucket, 90-day Glacier Deep Archive transition, 365-day expiration |
| **Observability & Identity** | CloudWatch Alarms, SNS Topic & Subscription, IAM | 6 | 2 CloudWatch Alarms, 1 SNS Topic, SSM Instance Profile, Lambda Execution Role |

---

## 3. Operational Evidence & Verification Walkthrough

The following sections detail the actual live testing conducted on AWS, supported by terminal outputs and AWS Management Console captures.

```
+---------------------------------------------------------------------------------------------------+
| TABLE OF CONTENTS - VISUAL EVIDENCE                                                              |
+---------------------------------------------------------------------------------------------------+
| 1. Figure 1: Terraform Outputs & Initial Lambda Auto-Stop Execution                               |
| 2. Figure 2: AWS Lambda FinOps Scheduler Architecture & Dual EventBridge Triggers                |
| 3. Figure 3: Amazon RDS PostgreSQL Status & Private Subnet Isolation                              |
| 4. Figure 4: RDS Inbound Security Group Chaining Verification                                     |
| 5. Figure 5: Amazon EC2 Stopped State & AWS Systems Manager (SSM) Profile                        |
| 6. Figure 6: EC2 Security Group Audit Confirming Zero Public Port 22 SSH Ingress                  |
| 7. Figure 7: Amazon CloudWatch Alarms Operational Health (State: OK)                              |
| 8. Figure 8: Amazon S3 Data Lake Bucket Glacier Deep Archive Lifecycle Configuration              |
| 9. Figure 9: Terraform Output Re-verification & Idempotent Lambda Stop Invocation                |
| 10. Figure 10: AWS CLI Tabular Health & Security Validation                                       |
| 11. Figure 11: Multi-Service FinOps Shell Script Audit Execution                                  |
| 12. Figure 12: Lambda Auto-Start Execution Resuming Compute & Database Workloads                  |
+---------------------------------------------------------------------------------------------------+
```

---

### Step 1: Infrastructure Deployment & Initial FinOps Trigger

Following execution of `terraform apply`, Terraform generated 8 critical infrastructure outputs. The Lambda instance scheduler was then invoked with payload `{"action": "stop"}` to simulate the evening shutdown routine.

![Figure 1: Terraform Outputs & Initial Lambda Auto-Stop Execution](docs/images/01_terraform_outputs_and_lambda_stop.png)
*Figure 1: Terminal display illustrating successful Terraform outputs (`rds_endpoint`, `ec2_instance_id`, `vpc_id`) followed by Lambda invocation returning HTTP 200: EC2 instance stopped and RDS database stop initiated.*

**Technical Observations:**
* `StatusCode: 200` confirms successful serverless invocation.
* The Lambda response body confirms targeted resource discovery via the `Environment=Dev` tag:
  * EC2: `["i-00d94d51d86756658"]` transitioned to stopped.
  * RDS: `cloudops-governance-dev-db` initiated shutdown.

---

### Step 2: Serverless FinOps Architecture Verification

Inspection of the AWS Lambda service console confirms that the function was deployed with least-privilege IAM permissions and dual EventBridge cron triggers.

![Figure 2: AWS Lambda FinOps Scheduler Architecture & Dual EventBridge Triggers](docs/images/02_lambda_architecture_and_eventbridge_triggers.png)
*Figure 2: AWS Management Console showing function `cloudops-governance-instance-scheduler` with two active EventBridge triggers: `start-morning-schedule` (08:00 Bangkok) and `stop-evening-schedule` (19:00 Bangkok).*

**Technical Observations:**
* Triggers are configured with standard POSIX cron syntax:
  * Morning Start: `cron(0 1 ? * MON-FRI *)` (01:00 UTC = 08:00 UTC+7).
  * Evening Stop: `cron(0 12 ? * MON-FRI *)` (12:00 UTC = 19:00 UTC+7).
* Non-production resources are completely powered down on weekends and outside working hours.

---

### Step 3: Database Isolation & Security Group Chaining

The database tier is hosted on Amazon RDS running PostgreSQL 15.13. Security audits verified that public internet connectivity is blocked and database access is restricted to the internal application security group.

![Figure 3: Amazon RDS PostgreSQL Status & Private Subnet Isolation](docs/images/03_rds_postgresql_stopped_private_isolation.png)
*Figure 3: Amazon RDS Console showing database `cloudops-governance-dev-db` in "Stopped temporarily" state with Internet access gateway disabled.*

![Figure 4: RDS Inbound Security Group Chaining Verification](docs/images/04_rds_security_group_chaining_rule.png)
*Figure 4: Security details of `cloudops-governance-rds-sg` showing Port 5432 ingress permitted exclusively from the EC2 Security Group (`sg-08455e646b795b6b8`).*

**Technical Observations:**
* Status is reported as **Stopped temporarily**, validating that the FinOps scheduler halted database compute hours to eliminate idle billing.
* **Zero Public Exposure:** `PubliclyAccessible = False` and `Internet access gateway = Disabled`.
* **Security Group Chaining:** Rather than allowing CIDR ranges like `10.0.0.0/16`, the database security group strictly references the source EC2 Security Group ID, enforcing least-privilege network segmentation.

---

### Step 4: Compute Hardening & Zero-Trust Access

The application compute instance was inspected to verify state transitions and ensure that management access complies with enterprise zero-trust standards.

![Figure 5: Amazon EC2 Stopped State & AWS Systems Manager (SSM) Profile](docs/images/05_ec2_instance_stopped_and_ssm_role.png)
*Figure 5: Amazon EC2 Console showing instance `i-00d94d51d86756658` in "Stopped" state, assigned to private subnet `10.0.1.242` and IAM role `cloudops-governance-ec2-ssm-role`.*

![Figure 6: EC2 Security Group Audit Confirming Zero Public Port 22 SSH Ingress](docs/images/06_ec2_security_group_no_ssh_port22.png)
*Figure 6: EC2 Security Details confirming only internal HTTP Port 80 is allowed. Public Port 22 (SSH) is completely omitted.*

**Technical Observations:**
* Instance state is confirmed as **Stopped**, confirming compute billing cessation.
* **Elimination of SSH Attack Surface:** Inbound rules contain zero references to Port 22 or `0.0.0.0/0`.
* **Secure Bastion-less Management:** The instance assumes an IAM profile with `AmazonSSMManagedInstanceCore`, enabling encrypted CLI access through AWS Systems Manager Session Manager without open ports or key pairs.

---

### Step 5: Incident Observability & S3 Storage Optimization

Observability and data retention policies were inspected to confirm real-time alerting and cold data storage cost cutting.

![Figure 7: Amazon CloudWatch Alarms Operational Health (State: OK)](docs/images/07_cloudwatch_alarms_ok_state.png)
*Figure 7: Amazon CloudWatch Console showing both alarms in "OK" state: `RDS-Free-Storage-Space-Low` (< 5 GB) and `EC2-CPU-Utilization-High` (> 80%).*

![Figure 8: Amazon S3 Data Lake Bucket Glacier Deep Archive Lifecycle Configuration](docs/images/08_s3_bucket_glacier_lifecycle_configuration.png)
*Figure 8: Amazon S3 Console showing bucket `cloudops-governance-data-lake-2afd2f97` with active lifecycle rule `archive-cold-data-to-glacier`.*

**Technical Observations:**
* Both CloudWatch alarms are healthy and active. Any metric breach routes notification payloads to the Amazon SNS topic `cloudops-governance-incident-alerts` for automated email delivery.
* The S3 Lifecycle rule applies to all objects in the bucket, automatically transitioning cold data to **Glacier Deep Archive** at 90 days ($0.00099/GB/month vs $0.023/GB/month for Standard), and expiring objects at 365 days.

---

### Step 6: CLI Status Auditing & FinOps Verification

Command-line verification was conducted using the AWS CLI and custom FinOps automation scripts to confirm resource health, idempotency, and automated anomaly detection.

![Figure 9: Terraform Output Re-verification & Idempotent Lambda Stop Invocation](docs/images/09_terraform_output_and_idempotent_stop.png)
*Figure 9: Terminal verification showing idempotent scheduler behavior: secondary stop invocation correctly identified the database as already stopped and safely skipped it.*

![Figure 10: AWS CLI Tabular Health & Security Validation](docs/images/10_aws_cli_ec2_and_rds_tabular_status.png)
*Figure 10: Tabular AWS CLI output verifying EC2 state as "stopped", RDS state as "stopped", engine version "15.13", and PubliclyAccessible as "False".*

![Figure 11: Multi-Service FinOps Shell Script Audit Execution](docs/images/11_finops_audit_shell_script_execution.png)
*Figure 11: Execution of `audit_finops_unused_resources.sh` auditing EBS volumes, stopped instances, S3 lifecycle configurations, and open security group ports.*

![Figure 12: Lambda Auto-Start Execution Resuming Compute & Database Workloads](docs/images/12_lambda_auto_start_execution.png)
*Figure 12: Terminal invocation of Lambda with payload `{"action": "start"}` confirming successful morning resume routine: EC2 started and RDS start initiated.*

**Technical Observations:**
* **Idempotency:** The Python Lambda function inspects resource states prior to issuing API calls, preventing redundant state change exceptions when invoked consecutively.
* **FinOps Script Intelligence:** The Bash audit script scanned across four dimensions:
  1. Unattached EBS Volumes: 0 found (Clean).
  2. Stopped EC2 Instances: Correctly detected instance `i-00d94d51d86756658` and reported advisory action.
  3. S3 Bucket Lifecycle: All audited buckets have valid lifecycle policies (Clean).
  4. World-Open Security Groups: 0 open management ports found (Clean).
* **Workload Resumption:** Figure 12 verifies the reverse workflow: invoking `start` returns HTTP 200 and transitions both EC2 and RDS back into active operation for the business day.

---

## 4. Financial & Cost Optimization Analysis

### 4.1 Compute & Database Runtime Comparison

In a standard AWS deployment without automated governance, development resources run continuously 24 hours a day, 7 days a week.

$$\text{Standard Runtime} = 24 \text{ hours} \times 7 \text{ days} = 168 \text{ hours/week}$$

Under this project's FinOps EventBridge schedule (Monday through Friday, 08:00 to 19:00):

$$\text{Governed Runtime} = 11 \text{ hours} \times 5 \text{ days} = 55 \text{ hours/week}$$

$$\text{Cost Reduction Percentage} = \frac{168 - 55}{168} \times 100\% = 67.26\%$$

### 4.2 Storage Tiering Economics

Log files and database backups stored in Amazon S3 Standard cost approximately **$0.023 per GB/month**. By transitioning objects older than 90 days to Amazon S3 Glacier Deep Archive:

$$\text{Glacier Deep Archive Cost} = \$0.00099 \text{ per GB/month}$$

$$\text{Storage Savings} = \frac{\$0.023 - \$0.00099}{\$0.023} \times 100\% = 95.70\%$$

### 4.3 Actual Monthly Billing Statement

Because all resource instance classes (`t3.micro`, `db.t3.micro`, 20 GB gp3 RDS storage, 8 GB gp3 EBS root volume, and serverless Lambda executions) were specifically provisioned within the **AWS 12-Month Free Tier**, total infrastructure spend during testing was:

$$\text{Total Infrastructure Spend} = \$0.00$$

---

## 5. Technical Interview Key Talking Points

When presenting this project in Cloud Engineering, DevOps, or FinOps technical interviews, emphasize the following architectural design decisions:

1. **Infrastructure as Code (IaC) Reproducibility:**
   > *"The entire 35-resource environment is declared immutably in Terraform. It can be provisioned in under 8 minutes via `terraform apply` and torn down completely in 5 minutes via `terraform destroy`, guaranteeing zero configuration drift and zero idle charges."*
2. **Defense-in-Depth & Zero Trust:**
   > *"Rather than relying on perimeter firewalls alone, the architecture implements Security Group Chaining between compute and database tiers, completely closes SSH Port 22 in favor of AWS Systems Manager Session Manager, and blocks public S3 access at the bucket policy level."*
3. **Event-Driven FinOps Architecture:**
   > *"We implemented a tag-based serverless scheduler using EventBridge and Python Lambda. By querying resources tagged `Environment=Dev`, the scheduler dynamically discovers and toggles compute instances without hardcoded resource IDs, cutting weekly runtime by over 67%."*
4. **Idempotent Automation:**
   > *"The automation logic inspects real-time instance states before executing actions, preventing API failure cascades if a database or server is already stopped or starting."*

---

## 6. Conclusion & Teardown Verification

All 35 resources deployed for this demonstration met architectural, security, and cost governance requirements. 

Following verification and evidence capture, the infrastructure can be cleanly removed by executing:

```bash
cd ~/User/AWS_Crawl/projects/cloudops-cost-governance/terraform
terraform destroy -auto-approve
```

All AWS RDS database resources include `skip_final_snapshot = true` and S3 storage resources include `force_destroy = true` to guarantee instant, automated, and zero-residual cleanup.
