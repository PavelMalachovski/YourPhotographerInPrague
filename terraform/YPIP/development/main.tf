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
# Provider and Modules
#=============================================================================

provider "aws" {
    region = var.region
}

module "aws_security_group" {
    source = "../../modules/aws_security_group"
    allow_ports = ["22","80","443","8080","1541","9092"]
}

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
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}
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
    key_name = aws_key_pair.generated_key.key_name
    instance_type = var.master_instance_type
    monitoring = var.detailed_monitoring
    vpc_security_group_ids = [module.aws_security_group.my_sg_id]
    tags = merge(var.common_tag, { Name = "${var.environment} ${var.master_instance_type} MASTER by Terraform"})
}

resource "aws_instance" "my_k8s_cluster_worker1" {
    ami = data.aws_ami.latest_amazon_linux.id
    key_name = aws_key_pair.generated_key.key_name
    instance_type = var.worker_instance_type
    monitoring = var.detailed_monitoring
    vpc_security_group_ids = [module.aws_security_group.my_sg_id]
    tags = merge(var.common_tag, { Name = "${var.environment} ${var.worker_instance_type} WORKER1 by Terraform"})
}

resource "aws_instance" "my_k8s_cluster_worker2" {
    ami = data.aws_ami.latest_amazon_linux.id
    key_name = aws_key_pair.generated_key.key_name
    instance_type = var.worker_instance_type
    monitoring = var.detailed_monitoring
    vpc_security_group_ids = [module.aws_security_group.my_sg_id]
    tags = merge(var.common_tag, { Name = "${var.environment} ${var.worker_instance_type} WORKER2 by Terraform"})
}
#=============================================================================
