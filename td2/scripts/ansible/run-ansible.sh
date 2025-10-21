#!/bin/bash

# Script pour exécuter le playbook Ansible create_ec2_instance_playbook.yml
# Usage: ./run-ansible.sh

set -e

echo "=== Ansible EC2 Instance Deployment ==="

# Configuration AWS - Les credentials doivent être définis comme variables d'environnement
# Exemple d'utilisation :
# export AWS_ACCESS_KEY_ID="your_access_key_here"
# export AWS_SECRET_ACCESS_KEY="your_secret_key_here"
# export AWS_DEFAULT_REGION="us-east-2"

# Vérifier que les credentials AWS sont configurés
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "❌ Error: AWS credentials not found!"
    echo "Please set the following environment variables:"
    echo "  export AWS_ACCESS_KEY_ID=\"your_access_key_here\""
    echo "  export AWS_SECRET_ACCESS_KEY=\"your_secret_key_here\""
    echo "  export AWS_DEFAULT_REGION=\"us-east-2\""
    exit 1
fi

# Définir la région par défaut si elle n'est pas définie
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-2}"

echo "✓ AWS credentials configured for region: $AWS_DEFAULT_REGION"

# Installer Ansible et les dépendances via apt
echo "Installing Ansible and dependencies via system packages..."
sudo apt-get update -qq
sudo apt-get install -y ansible python3-boto3 python3-botocore

echo "✓ Ansible and dependencies ready"

# Installer la collection Amazon AWS
echo "Installing/updating amazon.aws collection..."
ansible-galaxy collection install amazon.aws --force
echo "✓ amazon.aws collection ready"

# Exécuter le playbook
echo ""
echo "=== Executing create_ec2_instance_playbook.yml ==="
ansible-playbook -v create_ec2_instance_playbook.yml

echo ""
echo "=== Deployment completed! ==="

# Afficher les instances créées
echo ""
echo "=== Created instances ==="
aws ec2 describe-instances \
    --region us-east-2 \
    --filters "Name=tag:Ansible,Values=ch2_instances" "Name=instance-state-name,Values=pending,running" \
    --query "Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name,Tags[?Key=='Name'].Value|[0]]" \
    --output table

echo ""
echo "=== Security Groups ==="
aws ec2 describe-security-groups \
    --region us-east-2 \
    --group-names sample-app-ansible \
    --query "SecurityGroups[].[GroupId,GroupName,Description]" \
    --output table 2>/dev/null || echo "Security group not found or not accessible"

echo ""
echo "✓ Use 'chmod 600 ansible-ch2.key' to secure the private key"
echo "✓ SSH access: ssh -i ansible-ch2.key ec2-user@<PUBLIC_IP>"