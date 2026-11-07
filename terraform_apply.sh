#!/usr/bin/env bash
set -euo pipefail

#=============================================================================
# terraform apply + kubespray (master branch, protected "production" env).
#
# AWS credentials come from the environment (GitHub OIDC). Nothing secret is
# passed on the command line.
#
# Required env:
#   TF_STATE_BUCKET   S3 bucket with remote state
#   ADMIN_CIDR        your admin IP/CIDR, e.g. 203.0.113.10/32
#=============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${TF_STATE_BUCKET:?TF_STATE_BUCKET is not set}"
: "${ADMIN_CIDR:?ADMIN_CIDR is not set}"

# The runner must SSH into the nodes for kubespray, so temporarily allow its
# current public IP in addition to the admin CIDR. The rule is replaced on the
# next run when the runner IP changes.
RUNNER_IP="$(curl -fsS --max-time 10 https://checkip.amazonaws.com | tr -d '[:space:]')"
if [[ ! "${RUNNER_IP}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo "Could not determine runner public IP" >&2
  exit 1
fi
export TF_VAR_admin_cidr_blocks="[\"${ADMIN_CIDR}\",\"${RUNNER_IP}/32\"]"

cd "${PROJECT_DIR}/terraform/YPIP/development"
terraform init -input=false -backend-config="bucket=${TF_STATE_BUCKET}"
terraform plan -input=false -lock-timeout=120s -var-file=terraform.tfvars -out=tfplan
terraform apply -input=false -lock-timeout=120s tfplan
rm -f tfplan

#=============================================================================
# Terraform Output into vars
#=============================================================================
m1_ip="$(terraform output -raw my_k8s_cluster_master_public_ip)"
w1_ip="$(terraform output -raw my_k8s_cluster_worker1_public_ip)"
w2_ip="$(terraform output -raw my_k8s_cluster_worker2_public_ip)"

echo "============================================================================="
echo "Run kubespray setup"
echo "============================================================================="
cd "${PROJECT_DIR}"
bash ./kubespray.sh "${m1_ip}" "${w1_ip}" "${w2_ip}"
