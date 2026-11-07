#=============================================================================
# My Terraform Infrastructure
# 3-node Kubernetes cluster (1 master + 2 workers) for the WordPress site.
# Create:
#   - Security Group for K8s nodes (admin ports restricted to admin_cidr_blocks)
#   - SSH key pair (private key kept only in encrypted remote state + 0400 file)
#   - 3 EC2 instances: encrypted EBS, IMDSv2 only, Ubuntu 22.04 LTS
#   - Elastic IPs
#
# Pavel Malachovski
#=============================================================================

provider "aws" {
  region = var.region

  default_tags {
    tags = var.common_tag
  }
}

module "aws_security_group" {
  source            = "../../modules/aws_security_group"
  environment       = var.environment
  common_tag        = var.common_tag
  admin_cidr_blocks = var.admin_cidr_blocks
}

#=============================================================================
# Data Source
#=============================================================================

data "aws_ami" "ubuntu" {
  owners      = var.ami_owners
  most_recent = true

  filter {
    name   = "name"
    values = var.ami_name_filter
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#=============================================================================
# SSH key
#=============================================================================
resource "tls_private_key" "example" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.environment}-${var.key_name}"
  public_key = tls_private_key.example.public_key_openssh
}

# Written with 0400 perms instead of `echo '<key>' > key.pem` (which put the
# key on a command line and could leak it to logs / process list).
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.example.private_key_openssh
  filename        = "${path.module}/key.pem"
  file_permission = "0400"
}

#=============================================================================
# Instances
#=============================================================================
locals {
  nodes = {
    master  = var.master_instance_type
    worker1 = var.worker_instance_type
    worker2 = var.worker_instance_type
  }
}

resource "aws_instance" "node" {
  for_each = local.nodes

  ami                    = data.aws_ami.ubuntu.id
  key_name               = aws_key_pair.generated_key.key_name
  instance_type          = each.value
  monitoring             = var.detailed_monitoring
  ebs_optimized          = true
  vpc_security_group_ids = [module.aws_security_group.my_sg_id]

  # IMDSv2 only — blocks SSRF-style credential theft via IMDSv1.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2 # containers on the node still need IMDS
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${var.environment} ${each.value} ${upper(each.key)} by Terraform" }

  lifecycle {
    ignore_changes = [ami] # don't replace nodes every time a new AMI ships
  }
}

resource "aws_eip" "node" {
  for_each = aws_instance.node

  domain   = "vpc"
  instance = each.value.id
  tags     = { Name = "${var.environment} ${title(each.key)} Elastic IP" }
}
