#!/usr/bin/env bash
set -euo pipefail

#=============================================================================
# terraform plan (feature branches / PRs).
#
# AWS credentials come from the environment (GitHub OIDC via
# aws-actions/configure-aws-credentials). They are never passed as CLI
# arguments, which would expose them in `ps` output and shell traces.
#
# Required env:
#   TF_STATE_BUCKET              S3 bucket with remote state
#   TF_VAR_admin_cidr_blocks     e.g. '["203.0.113.10/32"]'
#=============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${TF_STATE_BUCKET:?TF_STATE_BUCKET is not set}"
: "${TF_VAR_admin_cidr_blocks:?TF_VAR_admin_cidr_blocks is not set}"

cd "${PROJECT_DIR}/terraform/YPIP/development"
terraform init -input=false -backend-config="bucket=${TF_STATE_BUCKET}"
terraform plan -input=false -lock-timeout=120s -var-file=terraform.tfvars
