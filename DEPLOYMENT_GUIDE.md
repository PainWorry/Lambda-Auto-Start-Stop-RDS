# Complete End-to-End Deployment & AWS Free Tier Setup Guide
**Enterprise AWS CloudOps & Cost Governance Automation Suite**  
*Document Version: 1.0.0 | Environment: Clean Machine (Ubuntu / Debian Linux) | Target Region: ap-southeast-1 (Singapore)*

---

## Table of Contents
1. [Prerequisites & Overview](#1-prerequisites--overview)
2. [Step 1: Creating a Free AWS Account from Scratch](#2-step-1-creating-a-free-aws-account-from-scratch)
3. [Step 2: Best Practice Security Setup (IAM Admin & Billing Alarm)](#3-step-2-best-practice-security-setup-iam-admin--billing-alarm)
4. [Step 3: Setting Up a Fresh Linux Workstation](#4-step-3-setting-up-a-fresh-linux-workstation)
5. [Step 4: Configuring AWS CLI Authentication](#5-step-4-configuring-aws-cli-authentication)
6. [Step 5: Project Setup & Variable Configuration](#6-step-5-project-setup--variable-configuration)
7. [Step 6: Provisioning Infrastructure via Terraform](#7-step-6-provisioning-infrastructure-via-terraform)
8. [Step 7: Operational Verification & Testing](#8-step-7-operational-verification--testing)
9. [Step 8: Complete Teardown ($0 Cost Clean-up)](#9-step-8-complete-teardown-0-cost-clean-up)
10. [Troubleshooting & Common Questions](#10-troubleshooting--common-questions)

---

## 1. Prerequisites & Overview

This guide assumes you are starting on a **completely fresh computer** running Ubuntu/Debian Linux and have **no prior AWS configuration**.

By following these instructions, you will:
* Register for a new AWS Account and qualify for the **12-Month AWS Free Tier**.
* Configure least-privilege IAM credentials for safe command-line automation.
* Install all required toolchains (`git`, `awscli v2`, `terraform`).
* Provision an enterprise Multi-AZ VPC, EC2 instance, RDS PostgreSQL instance, S3 data lake with Glacier lifecycle rules, CloudWatch observability alarms, and an automated Python Lambda scheduler.
* Validate the automation and safely destroy all provisioned infrastructure in under 10 minutes to maintain a strict **$0.00 spending footprint**.

---

## 2. Step 1: Creating a Free AWS Account from Scratch

AWS provides a 12-Month Free Tier offering 750 hours/month of `t2.micro`/`t3.micro` EC2 compute, 750 hours/month of `db.t3.micro` RDS database compute, 5 GB of Amazon S3 storage, and 1,000,000 free AWS Lambda requests per month.

### 2.1 What You Will Need Before You Begin
* A valid email address not previously registered with AWS.
* A credit or debit card (AWS will place a temporary hold of ~$1.00 USD for identity verification, which is automatically refunded within 3-5 business days).
* A mobile phone number capable of receiving SMS OTP verification codes.

### 2.2 Account Registration Steps

> [IMPORTANT NOTE: AWS CLOUD ACCOUNT VS. AWS BUILDER ID]  
> Do not confuse an **AWS Cloud Account** with an **AWS Builder ID**.  
> An **AWS Builder ID** (hosted at `profile.aws.amazon.com`) is only an individual developer profile for training and tools (e.g., Amazon Q, PartyRock). It does not have an AWS Account ID, IAM console, or infrastructure capabilities.  
> You need a genuine **AWS Cloud Account** which grants access to the **AWS Management Console** (`console.aws.amazon.com`) for EC2, RDS, VPC, and Terraform provisioning.

1. Open a new **Incognito / Private Browsing window** (recommended to avoid being redirected to a cached Builder ID session).
2. Navigate directly to the official AWS Cloud Account registration link:  
   **[https://portal.aws.amazon.com/billing/signup](https://portal.aws.amazon.com/billing/signup)**  
   *(Alternative: Go to [https://aws.amazon.com](https://aws.amazon.com) and click the orange **"Create an AWS Account"** button in the top right corner).*
3. **Step 1 - Root User Email:** Enter your email address and an **AWS account name** (e.g., `cloudops-lab`). Click **Verify email address**.
4. Check your inbox for the 6-digit verification code, submit it, and create a strong Root User password.
5. **Step 2 - Contact Information:** Select **Personal** (for personal projects, learning, and portfolio labs) and complete your full legal name, phone number, and address.
6. **Step 3 - Payment Information:** Enter your credit or debit card details. (AWS will initiate a temporary verification hold of ~$1.00 USD, automatically refunded within 3-5 business days).
7. **Step 4 - Identity Verification:** Enter your phone number, select **SMS**, and enter the 4-digit OTP code sent to your phone.
8. **Step 5 - Support Plan Selection:** Choose **Basic support - Free ($0/month)**. Do **not** select Developer or Business support.
9. Click **Complete sign up** and wait 2 to 5 minutes for account activation.
10. Navigate to the [AWS Management Console](https://console.aws.amazon.com/) to confirm active cloud access.

---

## 3. Step 2: Best Practice Security Setup (IAM Admin & Billing Alarm)

> [CRITICAL SECURITY RULE]  
> Never use the Root Account or Root Access Keys for daily development, Terraform execution, or CLI commands. Root credentials have unrestricted permissions and cannot be revoked without disabling the entire account.

### 3.1 Create an IAM Administrator User
1. Log in to the [AWS Management Console](https://console.aws.amazon.com/) as the **Root user**.
2. In the top search bar, search for **IAM** and select it.
3. In the left navigation menu, click **Users** > **Create user**.
4. Set the **User name** to `cloudops-admin`. Leave the console password checkbox unchecked if you only intend to use this user for CLI/Terraform, or enable console access if preferred. Click **Next**.
5. Under **Permissions options**, select **Attach policies directly**.
6. Search for `AdministratorAccess`, check the box next to it, and click **Next**.
7. Review the user configuration and click **Create user**.

### 3.2 Generate CLI Access Keys
1. In the IAM Users list, click on the newly created user `cloudops-admin`.
2. Select the **Security credentials** tab.
3. Scroll down to the **Access keys** section and click **Create access key**.
4. Select the use case: **Command Line Interface (CLI)**. Check the acknowledgment box and click **Next**.
5. Set a description tag (e.g., `laptop-terraform-cli`) and click **Create access key**.
6. **Download the .csv file** or immediately copy:
   * **Access Key ID** (e.g., `AKIAIOSFODNN7EXAMPLE`)
   * **Secret Access Key** (e.g., `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)
   *(Store these securely. The Secret Key will never be displayed again.)*

### 3.3 Set Up a Zero-Spend Billing Alarm
1. In the AWS Console, search for **Billing and Cost Management**.
2. In the left navigation pane, click **Budgets** > **Create budget**.
3. Select **Cost budget (Recommended)**.
4. Set **Budget amount** to `$1.00` per month.
5. Set up an alert threshold at `80%` and input your personal email address.
6. Confirm and activate the budget. You will now receive instant email alerts if any billable charge exceeds $0.80 USD.

---

## 4. Step 3: Setting Up a Fresh Linux Workstation

Open your terminal on your clean Ubuntu or Debian machine and execute the following installation steps.

### 4.1 Update System Packages & Install Core Utilities
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget unzip git python3 python3-pip lsb-release gnupg software-properties-common
```

### 4.2 Configure Git Global User
```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
git config --global init.defaultBranch main
```

### 4.3 Install Official AWS CLI v2
AWS recommends installing the standalone v2 binary bundle:
```bash
# Download and install AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update

# Verify installation
aws --version
# Expected output: aws-cli/2.x.x Python/3.x.x Linux/...
```

### 4.4 Install HashiCorp Terraform (Official Repository)
```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add official repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
sudo apt update && sudo apt install -y terraform

# Verify installation
terraform -version
# Expected output: Terraform v1.x.x
```

---

## 5. Step 4: Configuring AWS CLI Authentication

Authenticate your terminal session using the IAM credentials created in Step 2.

### 5.1 Run `aws configure`
```bash
aws configure
```

Enter your information when prompted:
```text
AWS Access Key ID [None]: <Paste your Access Key ID (AKIA...)>
AWS Secret Access Key [None]: <Paste your Secret Access Key>
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

### 5.2 Validate Connection & Identity
Run the STS (Security Token Service) caller identity check:
```bash
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDASAMPLEUSERIDEXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/cloudops-admin"
}
```
If you see your AWS Account ID and username `cloudops-admin`, authentication is fully verified.

---

## 6. Step 5: Project Setup & Variable Configuration

### 6.1 Clone or Navigate to the Project Repository
If cloning from GitHub on your fresh computer:
```bash
cd ~
git clone https://github.com/<YOUR_GITHUB_USERNAME>/Lambda-Auto-Start-Stop-RDS.git
cd Lambda-Auto-Start-Stop-RDS
```

*(Or navigate to your local workspace directory:)*
```bash
cd /path/to/cloudops-cost-governance
```

### 6.2 Set Up Terraform Input Variables
Navigate to the `terraform` subfolder:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your text editor (`nano`, `vim`, or VS Code):
```hcl
aws_region   = "ap-southeast-1"
project_name = "cloudops-governance"
environment  = "Dev"

# Replace with your actual email address to receive CloudWatch incident alerts
alert_email  = "alerts@example.com"

# Master database credentials for the Free-Tier PostgreSQL instance
db_username  = "dbadmin"
db_password  = "CloudOpsPass2026!"
```

---

## 7. Step 6: Provisioning Infrastructure via Terraform

### 7.1 Initialize Terraform
Downloads the required AWS provider (~5.0) and Archive provider plugins:
```bash
terraform init
```
**Expected output:** `Terraform has been successfully initialized!`

### 7.2 Run Execution Plan (Dry-Run Inspection)
```bash
terraform plan
```
Review the execution plan. Terraform will summarize the 20+ resources to be created without making any changes to your AWS account.

### 7.3 Deploy Resources to AWS
```bash
terraform apply -auto-approve
```

### 7.4 Deployment Timeline & Progress
* **Phase 1 (0 to 1 min):** Networking layer deployed (VPC `10.0.0.0/16`, Internet Gateway, 2 Public Subnets, 2 Private Subnets, Route Tables, and Security Groups).
* **Phase 2 (1 to 2 min):** IAM Roles, IAM Policies, S3 Data Lake Bucket with 90-day Glacier lifecycle policy, and CloudWatch Alarms created.
* **Phase 3 (2 to 3 min):** Python Lambda function packaged and deployed with EventBridge cron rules (19:00 Stop, 08:00 Start). EC2 `t3.micro` instance launched.
* **Phase 4 (3 to 8 min):** Amazon RDS PostgreSQL (`db.t3.micro`) provisioned across Multi-AZ subnets. *Note: RDS instances require 5 to 8 minutes on AWS for physical storage allocation and health verification.*

**Completed Output Example:**
```text
Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

Outputs:
cloudwatch_alarm_ec2_cpu = "arn:aws:cloudwatch:ap-southeast-1:...:alarm:cloudops-governance-EC2-CPU-Utilization-High"
cloudwatch_alarm_rds_storage = "arn:aws:cloudwatch:ap-southeast-1:...:alarm:cloudops-governance-RDS-FreeStorageSpace-Low"
ec2_instance_id = "i-0a1b2c3d4e5f67890"
lambda_scheduler_arn = "arn:aws:lambda:ap-southeast-1:...:function:cloudops-governance-instance-scheduler"
rds_endpoint = "cloudops-governance-dev-database....ap-southeast-1.rds.amazonaws.com:5432"
s3_data_lake_bucket = "cloudops-governance-data-lake-a1b2c3d4"
sns_alerts_topic_arn = "arn:aws:sns:ap-southeast-1:...:cloudops-governance-incident-alerts"
vpc_id = "vpc-0123456789abcdef0"
```

---

## 8. Step 7: Operational Verification & Testing

Verify that your infrastructure operates as designed according to AWS Well-Architected and FinOps standards.

### 8.1 Confirm SNS Email Subscription
1. Check the inbox for the email address provided in `alert_email`.
2. Look for an email from **AWS Notifications** with the subject *AWS Notification - Subscription Confirmation*.
3. Click the **"Confirm subscription"** link.
4. Your browser will display *Subscription confirmed!*. You will now receive automated alerts whenever CloudWatch alarms trigger.

### 8.2 Test the Lambda Start/Stop FinOps Scheduler
Simulate an automated off-hours trigger to verify that the Lambda function can stop non-production EC2 and RDS instances on demand:

```bash
aws lambda invoke \
  --function-name cloudops-governance-instance-scheduler \
  --payload '{"action": "stop"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json
```

**Expected JSON Response:**
```json
{
  "statusCode": 200,
  "body": "{\"message\": \"Auto-stop completed successfully for environment Dev.\"}"
}
```

Check the AWS Console or run the following CLI check to confirm the instances are stopping:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=Dev" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name]" \
  --output table
```

To test restarting them:
```bash
aws lambda invoke \
  --function-name cloudops-governance-instance-scheduler \
  --payload '{"action": "start"}' \
  --cli-binary-format raw-in-base64-out \
  response.json
```

### 8.3 Run the FinOps Infrastructure Hygiene Script
Execute the custom Bash audit script to scan for unattached EBS volumes, stopped instances, and permissive security groups:

```bash
cd ../scripts
chmod +x audit_finops_unused_resources.sh
./audit_finops_unused_resources.sh
```

**Expected Output:**
```text
==============================================================================
  AWS FINOPS & GOVERNANCE AUDIT REPORT
  Region: ap-southeast-1  |  Timestamp: 2026-10-11 03:00:00
==============================================================================

[*] Step 1: Scanning for Unattached EBS Volumes (Status = available)...
  [OK] Clean: 0 unattached EBS volumes found. No wasted storage.

[*] Step 2: Scanning for Stopped EC2 Instances (Status = stopped)...
  [OK] Clean: 0 stopped instances found.

[*] Step 3: Auditing S3 Buckets for Missing Lifecycle Rules...
  [OK] Clean: All audited buckets have lifecycle rules configured.

[*] Step 4: Auditing Security Groups for World-Open Management Ports (0.0.0.0/0)...
  [OK] Clean: No world-open security group rules detected.

==============================================================================
  AUDIT COMPLETE: All findings logged.
==============================================================================
```

---

## 9. Step 8: Complete Teardown ($0 Cost Clean-up)

When you are finished testing or capturing screenshots for your portfolio, destroy all infrastructure immediately to ensure zero ongoing charges.

### 9.1 Run `terraform destroy`
```bash
cd ../terraform
terraform destroy -auto-approve
```

### 9.2 Why Teardown is Clean & Reliable
* **RDS Clean Deletion:** The database resource includes `skip_final_snapshot = true`, preventing RDS deletion errors and avoiding billable snapshot storage costs.
* **S3 Clean Deletion:** The bucket resource includes `force_destroy = true`, allowing automated deletion even if log files were created.
* **Duration:** All 24 resources (VPC, Subnets, Gateways, EC2, RDS, Lambda, S3, CloudWatch, SNS) are deleted in approximately **5 to 8 minutes**.

### 9.3 Verify Clean State
```bash
aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,State.Name]" --output table
aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]" --output table
```
Both queries should return empty results. Your AWS bill will remain **$0.00**.

---

## 10. Troubleshooting & Common Questions

### Q1: `terraform apply` fails with `InvalidParameterValue: The parameter MasterUserPassword is not valid`
* **Cause:** AWS RDS requires passwords to be at least 8 characters long and avoid characters like `/`, `@`, `"`, or spaces.
* **Fix:** Use a standard alphanumeric string with special characters like `!` or `#` (e.g., `CloudOpsPass2026!`) in `terraform.tfvars`.

### Q2: `aws: error: the following arguments are required: --payload` or base64 decoding error
* **Cause:** AWS CLI v2 expects payload strings to be encoded in base64 by default.
* **Fix:** Always include the flag `--cli-binary-format raw-in-base64-out` when using `aws lambda invoke`.

### Q3: How do I SSH into the EC2 instance if Port 22 is closed?
* **Answer:** This architecture deliberately blocks public Port 22 according to enterprise security standards. Access the instance securely via **AWS Systems Manager (SSM Session Manager)**:
  ```bash
  aws ssm start-session --target <EC2_INSTANCE_ID>
  ```
  *(Requires `session-manager-plugin` installed on your machine).*

### Q4: Will I be charged if I leave the system running for 24 hours?
* **Answer:** Under the 12-Month AWS Free Tier:
  * `t3.micro` EC2: 750 free hours/month (1 instance can run 24/7 all month for free).
  * `db.t3.micro` RDS: 750 free hours/month (1 database can run 24/7 all month for free).
  * S3 Storage: 5 GB free.
  * Lambda: 1,000,000 requests free.
  * However, running `terraform destroy` when not in use is considered best engineering practice to avoid accidental quota consumption.
