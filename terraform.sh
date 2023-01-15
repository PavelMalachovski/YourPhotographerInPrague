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

export ${AWS_SECRET_ACCESS_KEY}
export ${AWS_ACCESS_KEY_ID}
#=============================================================================

cd ${PROJECT_DIR}/terraform/YPIP/development
terraform init && terraform plan #&& terraform apply
  #-var-file=secret.tfvars \
 #-var-file=secret.tfvars 
#\-auto-approve
#=============================================================================

#=============================================================================
# Terraform Output into vars:
#=============================================================================
m1_ip="$(terraform output my_k8s_cluster_master_public_ip)"
w1_ip="$(terraform output my_k8s_cluster_worker1_public_ip)"
w2_ip="$(terraform output my_k8s_cluster_worker2_public_ip)"

# echo " "
# echo "Run kubespray setup"
# echo "============================================================================="

# cd .. && echo "moving to $(pwd)"
# bash ./kubespray.sh "${m1_ip}" \
# "${w1_ip}" \
# "${w2_ip}"
