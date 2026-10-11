# Enterprise FinOps & Resource Ops Portal

A modern, interactive, and zero-cloud-cost Front-End dashboard for the **AWS CloudOps & Cost Governance Automation Suite**.

This portal gives recruiters, engineering managers, and interview panels an intuitive, interactive window into the system's infrastructure health, security controls, serverless automation, and cost-governance economics.

---

## 1. Quick Start: How to Run

### Method A: Single-Command Local Server (Recommended)
From the repository root:
```bash
./dashboard/start_dashboard.sh
```
* The script starts a lightweight local HTTP server on port `8080` and opens `http://localhost:8080` in your default browser.

### Method B: Direct Browser Open
Simply double-click `dashboard/index.html` or run:
```bash
xdg-open dashboard/index.html
```

---

## 2. Interactive Features & Demo Guide for Interviews

| Feature / Action Button | What Happens | What It Proves to the Interviewer |
| :--- | :--- | :--- |
| **Trigger Auto-Stop (19:00 Routine)** | Transitions EC2 to `STOPPED` and RDS to `STOPPED TEMPORARILY`, zeroes CPU gauge, and logs the real JSON payload returned by Boto3. | Demonstrates understanding of off-hours automation cutting compute hours from 168h/wk to 55h/wk (-67.26%). |
| **Trigger Auto-Start (08:00 Routine)** | Powers on EC2 and RDS, animates baseline CPU activity (14.2%), and outputs HTTP 200 payload. | Proves seamless workload resumption for business hours without manual operator intervention. |
| **Simulate CPU Spike (>80%)** | Spikes EC2 CPU to 94.8%, triggers CloudWatch metric alarm into `ALARM (>80%)` with pinging badge, and opens the realistic **AWS SNS Email Incident Alert** modal. | Highlights defense-in-depth observability and incident response automation. |
| **Run FinOps Audit** | Prints real-time multi-service governance audit stream checking for orphaned EBS volumes, stopped instances, S3 lifecycle rules, and world-open security groups. | Demonstrates strong compliance, automated policy enforcement, and Shell scripting skills. |
| **Interactive Mode Switcher** | Toggles between **Demo Simulator** ($0 spend, 100% reliable offline) and **Live AWS API**. | Proves architectural maturity: you can present your portfolio anytime without keeping billable cloud instances running. |

---

## 3. Pre-Configured Live Project Telemetry

The portal comes pre-loaded with the actual AWS resource IDs and configuration generated during our Terraform deployment in region `ap-southeast-1`:
* **EC2 Instance:** `i-00d94d51d86756658` (Amazon Linux 2023, SSM Profile `cloudops-governance-ec2-ssm-role`, Port 22 Closed)
* **RDS PostgreSQL:** `cloudops-governance-dev-db` (PostgreSQL 15.13, Private Subnet, `PubliclyAccessible: False`, Port 5432 Chained to EC2 SG)
* **S3 Data Lake:** `cloudops-governance-data-lake-2afd2f97` (Glacier Deep Archive >90d, 365d Expire, 100% Public Access Blocked)
* **Lambda Function:** `cloudops-governance-instance-scheduler` (EventBridge Dual Cron Triggers)
* **Incident Alarms:** `cloudops-governance-EC2-CPU-Utilization-High` and `cloudops-governance-RDS-Free-Storage-Space-Low`
* **SNS Notification Topic:** `cloudops-governance-incident-alerts` (`herren1809@gmail.com`)

---

## 4. Key Talking Points for Technical Interviews

When demonstrating this portal to interviewers:
1. **Platform Engineering / Internal Developer Platform (IDP):**
   > *"In enterprise environments, developers need self-service visibility into their non-production workloads without having full IAM console permissions. I built this portal to bridge that gap while giving FinOps leads automated cost governance."*
2. **Deterministic FinOps Economics:**
   > *"By automating shutdown during non-business hours, we cut weekly compute hours from 168 down to 55 hours, achieving an immediate 67.26% reduction in compute spend. Coupled with S3 Glacier Deep Archive tiering for cold logs, storage overhead drops by 95.7%."*
3. **Zero-Trust Posture:**
   > *"Notice that Port 22 is completely omitted. Management access is handled securely via AWS Systems Manager Session Manager, and database ingress is chained exclusively to the EC2 security group."*
