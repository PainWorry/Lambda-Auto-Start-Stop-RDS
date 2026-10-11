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

## 1. Prerequisites, Objectives & Project Overview

### 1.1 Project Objectives
This project implements an enterprise-grade cloud automation suite designed to solve the real-world operational challenges of cloud cost overrun, security vulnerabilities, and infrastructure drift:
* **Infrastructure as Code (IaC) Reproducibility:** Provision an immutable, multi-tiered AWS cloud environment (35 resources) deterministically using Terraform.
* **FinOps Automated Cost Governance:** Reduce non-production cloud spend by automating off-hours shutdowns via AWS EventBridge and Python 3.12 Lambda, cutting weekly compute/database runtime from 168 hours to 55 hours (**67.26% cost reduction**).
* **Zero-Trust Network Isolation:** Eliminate public SSH Port 22 completely in favor of **AWS Systems Manager (SSM Session Manager)**; enforce **Security Group Chaining** so the PostgreSQL database is accessible only from the application tier.
* **Storage Tiering Optimization:** Enforce automated S3 Lifecycle rules transitioning cold data older than 90 days to **Amazon S3 Glacier Deep Archive**, cutting storage costs by **95.70%**.
* **Proactive Observability:** Monitor compute health and database storage in real time using Amazon CloudWatch metric alarms connected to Amazon SNS for instant email incident alerting.
* **Multi-Service Governance Auditing:** Execute custom shell scripts to audit unattached EBS volumes, stopped instances, S3 lifecycle policies, and open security groups.

### 1.2 Tools & Technologies Used
| Category | Tool / Technology | Purpose |
| :--- | :--- | :--- |
| **Cloud Platform** | Amazon Web Services (AWS) | Core provider: VPC, EC2, RDS PostgreSQL, Lambda, EventBridge, CloudWatch, SNS, S3, IAM, SSM |
| **Infrastructure as Code** | HashiCorp Terraform v1.9.8 | Declarative infrastructure orchestration (AWS Provider ~> 5.0, Archive Provider ~> 2.4, Random ~> 3.6) |
| **Automation & Runtimes** | Python 3.12 (AWS Boto3 SDK) | Serverless event-driven start/stop scheduler Lambda function |
| **Scripting & Toolchains** | Bash / POSIX Shell | Automated FinOps resource auditing script (`scripts/audit_finops_unused_resources.sh`) |
| **CLI & Authentication** | AWS CLI v2 | Command-line management, query filtering, and authentication |
| **Version Control** | Git & GitHub | Source code management with security filters preventing secret leakage |
| **Reporting & Formats** | Markdown (.md) & Word (.docx) | Automated generation of executive engineering verification reports with embedded evidence |

### 1.3 Cost Analysis & $0.00 Free Tier Budget Guarantee
All resource tiers in this project are strictly selected within the limits of the **AWS 12-Month Free Tier**:
| Service & Resource | AWS Free Tier Allowance | Project Usage | Actual Monthly Cost |
| :--- | :--- | :--- | :--- |
| **Amazon EC2 (`t3.micro`)** | 750 hours/month | ~220 hours/month (Governed by FinOps Scheduler) | **$0.00** |
| **Amazon RDS (`db.t3.micro`)** | 750 hours/month | ~220 hours/month (Governed by FinOps Scheduler) | **$0.00** |
| **Amazon RDS Storage** | 20 GB gp2/gp3 storage | 20 GB gp3 storage | **$0.00** |
| **EBS Root Volume** | 30 GB total storage | 8 GB gp3 storage | **$0.00** |
| **Amazon S3 Storage** | 5 GB Standard storage | < 100 MB | **$0.00** |
| **AWS Lambda Requests** | 1,000,000 requests/month | ~60 requests/month (2 runs per business day) | **$0.00** |
| **Amazon CloudWatch** | 10 Metric Alarms free | 2 Metric Alarms | **$0.00** |
| **VPC, Subnets, IAM, SSM** | Always Free | Fully utilized | **$0.00** |
| **Total Project Spend** | - | - | **$0.00** |

### 1.4 Expected Results Upon Completion
When you complete this project, you will have:
1. **Fully Deployed Cloud Infrastructure:** 35 active AWS resources provisioned via Terraform without errors.
2. **Operational FinOps Automation:** Invoking the Lambda scheduler with `{"action": "stop"}` stops EC2 and RDS instances; invoking `{"action": "start"}` resumes them.
3. **Verified Hardened Security:** The PostgreSQL RDS instance is private (`PubliclyAccessible = False`), and EC2 has zero public SSH Port 22 open.
4. **CloudWatch Alarms in OK State:** Both EC2 CPU (>80%) and RDS storage (<5 GB) alarms are active and healthy.
5. **FinOps Audit Script Pass:** The audit script executes cleanly and flags stopped instances to maintain cost awareness.
6. **Comprehensive Documentation:** Full photographic evidence captured in `docs/images/` and documented in `PROJECT_EXECUTION_REPORT.md` and `PROJECT_EXECUTION_REPORT.docx`.

### 1.5 Recommendations: Common Problems & How to Avoid Them
Based on real-world engineering troubleshooting logs (documented in `log.txt`):
* **Problem 1 (AWS Builder ID Redirection):** Opening generic signup pages can redirect you to an AWS Builder ID profile rather than an AWS Cloud Account.  
  *How to avoid:* Use an incognito browsing window and navigate directly to `https://portal.aws.amazon.com/billing/signup`.
* **Problem 2 (Whitespace in Linux Paths):** Directory names with spaces (e.g., `AWS Crawl`) cause command-line syntax errors with bash scripts and Terraform plugins.  
  *How to avoid:* Use underscores or hyphens in directory names (e.g., `AWS_Crawl`).
* **Problem 3 (Terraform Package Manager on Linux Mint/Derivatives):** Linux Mint uses codename `zena`, causing HashiCorp APT repositories to return 404 (HashiCorp supports Ubuntu `noble`).  
  *How to avoid:* Install the official standalone 64-bit Terraform binary directly into `/usr/local/bin`.
* **Problem 4 (Executing from Wrong Directory):** Running `terraform plan` from the project root yields `Error: No configuration files`.  
  *How to avoid:* Always change directory into `terraform/` (`cd terraform`) before running Terraform commands.
* **Problem 5 (Inconsistent Dependency Lock File):** Running `terraform plan` before initializing plugins yields lock file errors.  
  *How to avoid:* Always execute `terraform init` before running `plan` or `apply`.
* **Problem 6 (S3 Lifecycle Invalid Attribute Combination):** In AWS Provider v5+, lifecycle rules targeting all bucket objects require an explicit `filter {}` block.  
  *How to avoid:* Ensure `filter {}` is present inside the `rule` block in `main.tf`.
* **Problem 7 (PostgreSQL Version Deprecation):** AWS periodically deprecates older patch releases (e.g., PostgreSQL 15.7 was retired in `ap-southeast-1`).  
  *How to avoid:* Always verify orderable versions via `aws rds describe-orderable-db-instance-options` and use an active patch (e.g., `15.13`).
* **Problem 8 (Committing Plan Files to Version Control):** `tfplan` files contain decrypted sensitive values (e.g., database passwords).  
  *How to avoid:* Ensure `*.tfplan` and `tfplan` are explicitly listed in `.gitignore`.
* **Problem 9 (Interactive Input Quotes in AWS CLI):** Entering quotation marks `""` during `aws configure` causes authentication failures.  
  *How to avoid:* Paste raw key strings without any quotation marks.
* **Problem 10 (Git Non-Fast-Forward Rejection):** Remote repositories created with template READMEs reject initial push commands.  
  *How to avoid:* Use `git push -u origin main --force` on initial repository initialization.

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

### 3.3 Set Up a Zero-Spend Budget Alarm ($0.01 Threshold)
1. In the AWS Console top search bar, search for **AWS Budgets** (or navigate to **Billing and Cost Management** > **Budgets**).
2. Click **Create budget**.
3. Under **Budget setup**, select **Use a template (simplified)**.
4. Under **Templates (new)**, select **Zero spend budget**:
   * *Description: "Create a budget that notifies you once your spending exceeds $0.01."*
   * This is AWS's official recommended template for Free Tier accounts. It triggers an instant alert at the very first cent ($0.01 USD / ~0.35 THB) of billable usage.
5. In the **Email recipients** field, enter your email address for budget alerts (e.g., `alerts@example.com`).
6. Click **Create budget** to activate.

![AWS Zero Spend Budget Setup](docs/images/aws_zero_spend_budget.png)

---

## 4. Step 3: Setting Up a Fresh Linux Workstation

Open your terminal on your clean Ubuntu or Debian machine and execute the following installation steps.

### 4.1 Update System Packages & Install Core Utilities
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget unzip git python3 python3-pip lsb-release gnupg software-properties-common
```

### 4.2 Configure Git Global User
Configure your identity for commit history.

> [IMPORTANT: KEEP THE QUOTATION MARKS ""]  
> Always keep the double quotation marks `""` and replace only the text *inside* them:  
> * **Name:** Quotes are mandatory if your name contains spaces (e.g., `"John Doe"` or `"PainWorry"`). Without quotes, the shell will treat the second word as an unrecognized argument and throw an error.  
> * **Email:** Enclose your plain email inside quotes (e.g., `"yourname@gmail.com"`). Do not enter markdown links or formatting brackets.  
> * **Default Branch:** The third command sets `main` as the default branch name (run as-is without quotes).

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

### 4.4 Install HashiCorp Terraform
Install the official Terraform binary directly (works reliably across all Linux distributions including Ubuntu and Linux Mint):
```bash
# Download official 64-bit Linux binary
cd /tmp
wget https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip
unzip -o terraform_1.9.8_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform -version
# Expected output: Terraform v1.9.8
```

*(Alternative via APT Repository for Ubuntu/Mint users:)*
```bash
# Note: Linux Mint users should use UBUNTU_CODENAME (e.g., noble) rather than Mint codename (zena)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
UBUNTU_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2 || lsb_release -cs)
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
```

---

## 5. Step 4: Configuring AWS CLI Authentication

Authenticate your terminal session using the IAM credentials created in Step 2.

### 5.1 Run `aws configure`
```bash
aws configure
```

Enter your information when prompted:

> [IMPORTANT: DO NOT USE QUOTATION MARKS ""]  
> In interactive `aws configure` prompts, paste your raw keys and values directly **without** any quotation marks `""`.  
> If you enter quotes here, the AWS CLI will treat `"` as part of the key itself, resulting in authentication errors (`InvalidAccessKeyId`).

```text
AWS Access Key ID [None]: <Paste your Access Key ID (AKIA...) without quotes>
AWS Secret Access Key [None]: <Paste your Secret Access Key without quotes>
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
# Example: cd ~/User/AWS_Crawl/projects/cloudops-cost-governance
```

> [TIP: AVOID SPACES IN LINUX FOLDER NAMES]  
> Always use underscores (`_`) or hyphens (`-`) instead of spaces when naming folders in Linux (e.g., use `AWS_Crawl` rather than `AWS Crawl`). Unquoted whitespace in Linux paths frequently causes bash scripts, Terraform provider downloads, and CLI utilities to fail with `No such file or directory` errors.

### 6.2 Set Up Terraform Input Variables
Navigate to the `terraform` subfolder and create your variables file from the example:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Edit `terraform.tfvars` inside the nano editor:
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

> [NOTE: DATABASE CREDENTIALS - LEAVE AS-IS OR CUSTOMIZE?]  
> * **Recommended (Leave as-is):** You can safely leave `db_username = "dbadmin"` and `db_password = "CloudOpsPass2026!"` exactly as they are. The RDS instance is isolated in a private subnet (with zero public internet access) and will be cleanly destroyed via `terraform destroy`. Keeping the default password guarantees you meet AWS RDS complexity rules without syntax errors.  
> * **If you want to customize the password:** The password must be at least 8 characters long and must **not** contain `/`, `@`, `"`, or spaces (e.g., `"MySecureLabPass2026!"`).  
> * **What you MUST change:** Only `alert_email` must be updated to your actual email (e.g., `"yourname@gmail.com"`) so AWS SNS can send you the confirmation link and incident alerts!  
> * **How to save and exit in nano:** Press `Ctrl + O`, press `Enter` to confirm the filename, then press `Ctrl + X` to exit back to the terminal.

---

## 7. Step 6: Provisioning Infrastructure via Terraform

### 7.1 Initialize Terraform
Downloads the required AWS provider (~5.0) and Archive provider plugins:
```bash
terraform init
```
**Expected output:** `Terraform has been successfully initialized!`

> [PRO-TIP: CENTRAL PLUGIN CACHE TO SAVE DISK SPACE]  
> By default, Terraform downloads the AWS provider binary (~450 MB) separately into each project's local `.terraform/` folder, which consumes gigabytes of storage over time.  
> You can configure a **central plugin cache** so Terraform downloads providers only once and shares them across all projects on your machine via lightweight symlinks:  
> ```bash
> # Create the central cache directory
> mkdir -p ~/.terraform.d/plugin-cache
> 
> # Enable central cache in your bash profile
> echo 'export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"' >> ~/.bashrc
> source ~/.bashrc
> ```
> After setting this up once, running `terraform init` across any project will link the cached provider in seconds rather than redownloading 450 MB!

### 7.2 Run Execution Plan (Dry-Run Inspection)
```bash
terraform plan
```
Review the execution plan. Terraform will inspect existing AWS state and calculate the 35 resources to be created without making any real changes to your AWS account.

> [NOTE: "You didn't use the -out option to save this plan..."]  
> * **What it means:** When running `terraform plan` alone, Terraform performs an in-memory speculative dry-run and prints the planned actions to the terminal without saving the execution plan to disk.  
> * **Is it an error?** No. It is an informational advisory notice from HashiCorp. When you run `terraform apply` subsequently, Terraform simply refreshes state and calculates the execution plan again before asking for confirmation.  
> * **Local Development Workflow:** Running `terraform plan` followed by `terraform apply` is the standard, safe, and recommended workflow on developer workstations.  
> * **Enterprise CI/CD Workflow:** In multi-engineer production pipelines (e.g., GitHub Actions, Terraform Cloud), teams run `terraform plan -out=tfplan` to lock the plan into a binary file, have it reviewed and approved, and then run `terraform apply tfplan` to guarantee deterministic execution without re-evaluating state.

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

### 8.4 Reviewing Verification Evidence & Reports
All operational proof points have been captured and compiled into:
* **Interactive Markdown Report:** [`PROJECT_EXECUTION_REPORT.md`](PROJECT_EXECUTION_REPORT.md)
* **Formatted Word Document Report:** [`PROJECT_EXECUTION_REPORT.docx`](PROJECT_EXECUTION_REPORT.docx)
* **Visual Evidence Gallery:** [`docs/images/`](docs/images/) containing Figures 1 through 12.

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

### Q5: What does the notice "You didn't use the -out option to save this plan..." mean?
* **Answer:** It is an informational best-practice notice from HashiCorp, not an error. In local developer workflows, running `terraform plan` followed by `terraform apply` is standard and safe. In automated production CI/CD pipelines, engineers pass `-out=tfplan` to serialize the reviewed plan into a binary artifact so that `terraform apply tfplan` executes deterministically without recalculating or re-evaluating state.

### Q6: Why did Terraform display `Warning: Invalid Attribute Combination` on `aws_s3_bucket_lifecycle_configuration`?
* **Cause:** In AWS Provider v5+, S3 lifecycle configuration rules require an explicit `filter {}` block inside each `rule` even if the rule applies to all objects in the bucket without a prefix filter.
* **Fix:** Add an empty `filter {}` block inside the `rule` block in `terraform/main.tf`.
