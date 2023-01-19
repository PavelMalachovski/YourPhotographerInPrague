#!/bin/bash
set -e

#=============================================================================
# Bash script to run terraform via Github Actions
#=============================================================================

#=============================================================================
# Variables
PROJECT_DIR="/home/runner/work/YourPhotographerInPrague/YourPhotographerInPrague"
AWS_SECRET_ACCESS_KEY=$1
AWS_ACCESS_KEY_ID=$2

export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
echo "env params exported"
#=============================================================================

cd ${PROJECT_DIR}/terraform/YPIP/development
terraform init && terraform apply -var-file=terraform.tfvars -auto-approve
#=============================================================================

#=============================================================================
# Terraform Output into vars:
#=============================================================================
m1_ip="$(terraform output my_static_ip_master)"
w1_ip="$(terraform output my_static_ip_worker1)"
w2_ip="$(terraform output my_static_ip_worker2)"

echo "============================================================================="
echo "Run kubespray setup"
echo "============================================================================="

cd ${PROJECT_DIR} && echo "moving to $(pwd)"
bash ./kubespray.sh "${m1_ip}" \
"${w1_ip}" \
"${w2_ip}"
