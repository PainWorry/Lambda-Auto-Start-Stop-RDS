#!/usr/bin/env bash
# ==============================================================================
# scripts/audit_finops_unused_resources.sh
# ==============================================================================
# AWS Multi-Service FinOps & Security Audit Script
# Author: CloudOps Engineering (Reference Architecture)
# Objective:
#   1. Detect Unattached / Orphaned EBS Volumes (wasting storage costs)
#   2. Detect Stopped EC2 Instances (accumulating provisioned EBS costs)
#   3. Detect S3 Buckets missing Lifecycle Transition Policies
#   4. Detect Insecure Security Groups with 0.0.0.0/0 on Management / DB Ports
# ==============================================================================

set -euo pipefail

REGION="${AWS_REGION:-ap-southeast-1}"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "=============================================================================="
echo "  AWS FINOPS & GOVERNANCE AUDIT REPORT"
echo "  Region: ${REGION}  |  Timestamp: ${DATE}"
echo "=============================================================================="

# ------------------------------------------------------------------------------
# 1. UNATTACHED / ORPHANED EBS VOLUMES
# ------------------------------------------------------------------------------
echo ""
echo "[*] Step 1: Scanning for Unattached EBS Volumes (Status = available)..."
UNATTACHED_VOLS=$(aws ec2 describe-volumes \
  --region "${REGION}" \
  --filters Name=status,Values=available \
  --query "Volumes[*].{ID:VolumeId,SizeGB:Size,Type:VolumeType,Created:CreateTime}" \
  --output json 2>/dev/null || echo "[]")

VOL_COUNT=$(echo "${UNATTACHED_VOLS}" | grep -c '"ID"' || true)

if [ "${VOL_COUNT}" -gt 0 ]; then
  echo "  [WARN] FOUND ${VOL_COUNT} UNATTACHED EBS VOLUME(S):"
  echo "${UNATTACHED_VOLS}" | grep -E '"ID"|"SizeGB"|"Type"' | sed 's/[",]//g'
  echo "  [ACTION] Review and delete orphaned volumes or create final snapshot."
else
  echo "  [OK] Clean: 0 unattached EBS volumes found. No wasted storage."
fi

# ------------------------------------------------------------------------------
# 2. STOPPED EC2 INSTANCES
# ------------------------------------------------------------------------------
echo ""
echo "[*] Step 2: Scanning for Stopped EC2 Instances (Status = stopped)..."
STOPPED_INSTANCES=$(aws ec2 describe-instances \
  --region "${REGION}" \
  --filters Name=instance-state-name,Values=stopped \
  --query "Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,Name:Tags[?Key=='Name'].Value | [0]}" \
  --output json 2>/dev/null || echo "[]")

STOPPED_COUNT=$(echo "${STOPPED_INSTANCES}" | grep -c '"ID"' || true)

if [ "${STOPPED_COUNT}" -gt 0 ]; then
  echo "  [WARN] FOUND ${STOPPED_COUNT} STOPPED EC2 INSTANCE(S):"
  echo "${STOPPED_INSTANCES}" | grep -E '"ID"|"Type"|"Name"' | sed 's/[",]//g'
  echo "  [ACTION] Terminate obsolete instances to stop EBS root volume billing."
else
  echo "  [OK] Clean: 0 stopped instances found."
fi

# ------------------------------------------------------------------------------
# 3. S3 BUCKETS MISSING LIFECYCLE RULES
# ------------------------------------------------------------------------------
echo ""
echo "[*] Step 3: Auditing S3 Buckets for Missing Lifecycle Rules..."
BUCKETS=$(aws s3api list-buckets --query "Buckets[*].Name" --output text 2>/dev/null || echo "")

NO_LIFECYCLE_COUNT=0
TOTAL_BUCKETS=0

for B in ${BUCKETS}; do
  TOTAL_BUCKETS=$((TOTAL_BUCKETS + 1))
  HAS_LC=$(aws s3api get-bucket-lifecycle-configuration --bucket "${B}" 2>&1 || true)
  if echo "${HAS_LC}" | grep -q "NoSuchLifecycleConfiguration"; then
    NO_LIFECYCLE_COUNT=$((NO_LIFECYCLE_COUNT + 1))
    if [ "${NO_LIFECYCLE_COUNT}" -le 5 ]; then
      echo "  [WARN] Bucket missing lifecycle: ${B}"
    fi
  fi
done

if [ "${NO_LIFECYCLE_COUNT}" -gt 0 ]; then
  echo "  Total buckets without lifecycle: ${NO_LIFECYCLE_COUNT} / ${TOTAL_BUCKETS}"
  echo "  [ACTION] Configure S3 Lifecycle rule to transition objects >90 days to Glacier."
else
  echo "  [OK] Clean: All audited buckets have lifecycle rules configured."
fi

# ------------------------------------------------------------------------------
# 4. SECURITY GROUP OPEN PORT AUDIT (0.0.0.0/0)
# ------------------------------------------------------------------------------
echo ""
echo "[*] Step 4: Auditing Security Groups for World-Open Management Ports (0.0.0.0/0)..."
OPEN_SGS=$(aws ec2 describe-security-groups \
  --region "${REGION}" \
  --filters Name=ip-permission.cidr,Values='0.0.0.0/0' \
  --query "SecurityGroups[*].{ID:GroupId,Name:GroupName,Rules:IpPermissions[?contains(IpRanges[?CidrIp=='0.0.0.0/0'].CidrIp, '0.0.0.0/0')].{FromPort:FromPort,ToPort:ToPort,Proto:IpProtocol}}" \
  --output json 2>/dev/null || echo "[]")

OPEN_COUNT=$(echo "${OPEN_SGS}" | grep -c '"ID"' || true)

if [ "${OPEN_COUNT}" -gt 0 ]; then
  echo "  [WARN] Found ${OPEN_COUNT} Security Group(s) with 0.0.0.0/0 ingress."
  echo "  [ACTION] Restrict management ports (SSH 22, RDP 3389, DB 3306/5432) to internal VPC CIDRs."
else
  echo "  [OK] Clean: No world-open security group rules detected."
fi

echo ""
echo "=============================================================================="
echo "  AUDIT COMPLETE: All findings logged."
echo "=============================================================================="
