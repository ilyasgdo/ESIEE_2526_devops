#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-eu-west-3}"

# CLI: --region R | -r R
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--region)
      REGION="$2"; shift 2;;
    *)
      echo "Usage: $0 [--region R]"; exit 1;;
  esac
done

# 1) Terminate all instances tagged Name=sample-app that are not terminated
ids=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sample-app" \
  --query "Reservations[].Instances[?State.Name!='terminated'].InstanceId" \
  --output text \
  --region "$REGION" || true)

if [[ -n "${ids:-}" ]]; then
  echo "Terminating instances: $ids"
  aws ec2 terminate-instances --instance-ids $ids --region "$REGION" >/dev/null
  echo "Waiting for termination..."
  aws ec2 wait instance-terminated --instance-ids $ids --region "$REGION"
  echo "Instances terminated."
else
  echo "No instances to terminate."
fi

# 2) Delete all security groups named sample-app
sgs=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=sample-app" \
  --query "SecurityGroups[].GroupId" \
  --output text \
  --region "$REGION" || true)

if [[ -n "${sgs:-}" ]]; then
  echo "Deleting security groups: $sgs"
  for sg in $sgs; do
    if aws ec2 delete-security-group --group-id "$sg" --region "$REGION" 2>/dev/null; then
      echo "Deleted SG: $sg"
    else
      echo "Could not delete SG: $sg (in use or not found)"
    fi
  done
else
  echo "No security groups to delete."
fi