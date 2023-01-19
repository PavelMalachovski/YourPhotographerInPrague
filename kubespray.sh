#!/bin/bash
set -e

echo "============================================================================="
echo "Creates k8s cluster using kubespray with a master node and 2 worker nodes"
echo "============================================================================="


################################################################################################
# Default Help bits
################################################################################################
# Exit script after printing help
helpFunction()
{
   echo ""
   echo "Usage: $0 masternode_public_ip workernode_public_ip workernode2_public_ip"
   echo "WARNING: You need to create key-val pair terraformec2.pem for access to your generated ec2 instances"
   echo "terraformec2.pem must be in the same folder as this sh"
   exit 1
}

# Begin script in case all parameters are correct
# TODO: read an array of nodes for both masters and workers
export ANSIBLE_TIMEOUT=60

MASTERNODE_PUBLIC_IP=$1 
WORKERNODE_PUBLIC_IP=$2 
WORKERNODE2_PUBLIC_IP=$3

MASTERNODE_PUBLIC_IP="${MASTERNODE_PUBLIC_IP//\"}"
WORKERNODE_PUBLIC_IP="${WORKERNODE_PUBLIC_IP//\"}"
WORKERNODE2_PUBLIC_IP="${WORKERNODE2_PUBLIC_IP//\"}"

PROJECT_DIR="/home/runner/work/YourPhotographerInPrague/YourPhotographerInPrague"
CLUSTER_NAME="my_kubespray_k8s"

# Print helpFunction in case parameters are empty
if [ -z "$MASTERNODE_PUBLIC_IP" ] || [ -z "$WORKERNODE_PUBLIC_IP" ] || [ -z "$WORKERNODE2_PUBLIC_IP" ]
then
   echo "Missing parameters";
   helpFunction
fi

################################################################################################

echo "============================================================================="
echo "Grabbing private key output from terraform"
echo "============================================================================="
# mkdir ~/.ssh
chmod 700 ~/.ssh
mv ${PROJECT_DIR}/terraform/YPIP/development/key.pem ~/.ssh/key.pem
chmod 400 ~/.ssh/key.pem
eval $(ssh-agent)
ssh-add -D
ssh-add ~/.ssh/key.pem


echo "============================================================================="
echo "Grabbing kubespray from git"
echo "============================================================================="
rm -rf kubespray
cd ${PROJECT_DIR}/terraform/YPIP/development
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray


echo "============================================================================="
echo "Installing kubespray requirements"
echo "============================================================================="

if pip3 install -r requirements.txt
then
   echo "kubespray requirements installed"
else
   apt -y install python3 && apt -y install python3-pip && pip3 install -r requirements.txt
fi


echo "============================================================================="
echo "Copy inventory/sample to our cluster config folder"
echo "============================================================================="
cp -rfp inventory/sample inventory/${CLUSTER_NAME}

echo "============================================================================="
echo "Update Ansible inventory file with inventory builder "
echo "============================================================================="
declare -a ADDRESSES=(${MASTERNODE_PUBLIC_IP} ${WORKERNODE_PUBLIC_IP} ${WORKERNODE2_PUBLIC_IP})
#CONFIG_FILE=inventory/${CLUSTER_NAME}/hosts.yaml python3 contrib/inventory_builder/inventory.py ${ADDRESSES[@]}
CONFIG_FILE=inventory/${CLUSTER_NAME}/hosts.ini python3 contrib/inventory_builder/inventory.py ${ADDRESSES[@]}

echo "============================================================================="
echo "Run kubespray playbook"
echo "============================================================================="
ls -la
echo "============================================================================="
cat inventory/${CLUSTER_NAME}/hosts.ini
echo "============================================================================="

ansible-playbook -i inventory/${CLUSTER_NAME}/hosts.ini cluster.yml --private-key ~/.ssh/key.pem -e ansible_user=ubuntu -b --become-user=root --flush-cache
