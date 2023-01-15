#=============================================================================
# My Terraform Infrastructure
# Provision Highly Available Web site in any region Default VPC
# Create:
#   - Security Group for K8s Servers
#   - Launch Configuration with auto AMI lookup
#   - Auto Scaling group using 2 availability zones
#   - Classic Load Balancer in 2 availability zones
#
# Pavel Malachovski
#=============================================================================

#=============================================================================
# Provider and Terraform
#=============================================================================

provider "aws" {
    region = var.region
}

#=============================================================================
# Git push
#=============================================================================
# locals {
#   timestamp = "${timestamp()}"
#   timestamp_sanitized = "${replace("${local.timestamp}", "/[-| |T|Z|:]/", "")}"

# }

# resource "null_resource" "cmd" {
#     provisioner "local-exec" {
#         command = "echo Terraform apply started: ${local.timestamp_sanitized} >> ../terraform.log"
#     }
#     triggers = {
#         always_run = "${timestamp()}"
#     }
# }


#=============================================================================
# Data Source
#=============================================================================

data "aws_availability_zones" "available" {}

data "aws_ami" "latest_amazon_linux" {
    owners = var.owners
    most_recent = true
    filter {
        name = "name"
        values = var.latest_amazon_linux
    }
}

#=============================================================================
# Resources
#=============================================================================

resource "aws_eip" "my_static_ip_master" {
  instance = aws_instance.my_k8s_cluster_master.id
  tags = merge(var.common_tag, { Name = "${var.environment} Master Elastic IP"})
}

resource "aws_eip" "my_static_ip_worker1" {
  instance = aws_instance.my_k8s_cluster_worker1.id
  tags = merge(var.common_tag, { Name = "${var.environment} Worker1 Elastic IP"})
}

resource "aws_eip" "my_static_ip_worker2" {
  instance = aws_instance.my_k8s_cluster_worker2.id
  tags = merge(var.common_tag, { Name = "${var.environment} Worker2 Elastic IP"})
}

resource "aws_instance" "my_k8s_cluster_master" {
    ami = data.aws_ami.latest_amazon_linux.id
    instance_type = var.master_instance_type
    monitoring = var.detailed_monitoring
    vpc_security_group_ids = [data.aws_security_group.my_sg.id]
    tags = merge(var.common_tag, { Name = "${var.environment} ${var.instance_type} MASTER by Terraform"})
}

resource "aws_instance" "my_k8s_cluster_worker1" {
    ami = data.aws_ami.latest_amazon_linux.id
    instance_type = var.worker_instance_type
    monitoring = var.detailed_monitoring
    vpc_security_group_ids = [data.aws_security_group.my_sg.id]
    tags = merge(var.common_tag, { Name = "${var.environment} ${var.instance_type} WORKER1 by Terraform"})
}

resource "aws_instance" "my_k8s_cluster_worker2" {
    ami = data.aws_ami.latest_amazon_linux.id
    instance_type = var.worker_instance_type
    monitoring = var.detailed_monitoring
    vpc_security_group_ids = [data.aws_security_group.my_sg.id]
    tags = merge(var.common_tag, { Name = "${var.environment} ${var.instance_type} WORKER2 by Terraform"})
}
#=============================================================================
