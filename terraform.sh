#!/bin/bash
set -e

#=============================================================================
#=============================================================================
# Bash script to run terraform via Github Actions
#=============================================================================
#=============================================================================

#=============================================================================
echo "Install terraform"
if ! rpm -qa | grep -i "terra"
then
  apt install -y apt-utils
  apt-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
  apt install -y terraform
fi
#=============================================================================

cd terraform
terraform init && terraform plan #&& terraform apply
  #-var-file=secret.tfvars \
 #-var-file=secret.tfvars 
#\-auto-approve


# echo " "
# echo "Run kubespray setup"
# echo "============================================================================="
# m1_ip="$(terraform output my_k8s_cluster_master_public_ip)"
# w1_ip="$(terraform output my_k8s_cluster_worker1_public_ip)"
# w2_ip="$(terraform output my_k8s_cluster_worker2_public_ip)"
# cd .. && echo "moving to $(pwd)"
# bash ./kubespray.sh "${m1_ip}" \
# "${w1_ip}" \
# "${w2_ip}"
