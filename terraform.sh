#!/bin/bash
set -e

#=============================================================================
# Bash script to run terraform via Github Actions
#=============================================================================

#=============================================================================
# Variables
PROJECT_DIR="/home/runner/work/YourPhotographerInPrague/YourPhotographerInPrague"
#=============================================================================
# echo "Install terraform"
# if ! rpm -qa | grep -i "terra"
# then
#     sudo apt update
#     sudo apt install wget unzip
#     TER_VER=`curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1'`
#     wget https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip
#     unzip -o terraform_${TER_VER}_linux_amd64.zip
#     sudo mv terraform /usr/local/bin/
#     which terraform
#     terraform version

# #   apt-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
# #   apt install -y terraform
# fi
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
