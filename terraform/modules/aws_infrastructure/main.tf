#=============================================================================
# My Terraform Infrastructure
# Provision Highly Available Web site in any region Default VPC
# Create:
#   - Security Group for web server
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
locals {
  timestamp = "${timestamp()}"
  timestamp_sanitized = "${replace("${local.timestamp}", "/[-| |T|Z|:]/", "")}"

}

resource "null_resource" "cmd" {
    provisioner "local-exec" {
        command = "echo Terraform apply started: ${local.timestamp_sanitized} >> ../terraform.log"
    }
    triggers = {
        always_run = "${timestamp()}"
    }
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

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_amazon_linux_machine.id
  tags = merge(var.common_tag, { Name = "${var.environment} Elastic IP"})
}

resource "aws_instance" "my_amazon_linux_machine" {
    ami = data.aws_ami.latest_amazon_linux.id
    instance_type = var.instance_type
    monitoring = var.detailed_monitoring
    tags = merge(var.common_tag, { Name = "${var.environment} ${var.instance_type} Linux by Terraform"})
}
#=============================================================================
