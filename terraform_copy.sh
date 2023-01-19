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
terraform init && terraform plan
#=============================================================================