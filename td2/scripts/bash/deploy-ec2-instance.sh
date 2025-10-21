#!/usr/bin/env bash

set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-eu-west-3}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults and CLI parsing
INSTANCE_COUNT="${INSTANCE_COUNT:-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--count)
      INSTANCE_COUNT="$2"; shift 2;;
    -r|--region)
      REGION="$2"; shift 2;;
    -t|--instance-type)
      INSTANCE_TYPE="$2"; shift 2;;
    *)
      echo "Usage: $0 [--count N] [--region R] [--instance-type T]"; exit 1;;
  esac
done

# Resolve latest Amazon Linux 2023 AMI (x86_64) in region
ami_id=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text \
  --region "$REGION")

if [[ "$ami_id" == "None" || -z "$ami_id" ]]; then
  echo "Failed to resolve AMI in region $REGION" >&2
  exit 1
fi

# Get default VPC
vpc_id=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text \
  --region "$REGION")

if [[ "$vpc_id" == "None" || -z "$vpc_id" ]]; then
  echo "No default VPC found in $REGION" >&2
  exit 1
fi

# Create or reuse security group
SG_NAME="sample-app"
security_group_id=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$vpc_id" \
  --query "SecurityGroups[0].GroupId" \
  --output text \
  --region "$REGION")

if [[ "$security_group_id" == "None" || -z "$security_group_id" ]]; then
  security_group_id=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "Allow HTTP traffic into the sample app" \
    --vpc-id "$vpc_id" \
    --query "GroupId" \
    --output text \
    --region "$REGION")
fi

# Allow inbound HTTP on port 80 (idempotent)
aws ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --protocol tcp \
  --port 80 \
  --cidr "0.0.0.0/0" \
  --region "$REGION" 2>/dev/null || true

# Launch instances
# Using INSTANCE_COUNT set via CLI/env above
run_out=$(aws ec2 run-instances \
  --image-id "$ami_id" \
  --instance-type "$INSTANCE_TYPE" \
  --security-group-ids "$security_group_id" \
  --user-data "file://$SCRIPT_DIR/user-data.sh" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sample-app}]' \
  --count "$INSTANCE_COUNT" \
  --query "Instances[*].InstanceId" \
  --output text \
  --region "$REGION")

# Wait for running state
aws ec2 wait instance-running --instance-ids $run_out --region "$REGION"

# Fetch public IPs
public_ips=$(aws ec2 describe-instances \
  --instance-ids $run_out \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text \
  --region "$REGION")

echo "Security Group ID = $security_group_id"
echo "Instance IDs = $run_out"
echo "Public IPs = $public_ips"
