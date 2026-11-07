variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "eu-central-1"
}

variable "ami_owners" {
  description = "AMI owner account IDs (099720109477 = Canonical)"
  type        = list(string)
  default     = ["099720109477"]
}

variable "ami_name_filter" {
  description = "AMI name filter (Ubuntu 22.04 LTS, supported by kubespray v2.26)"
  type        = list(string)
  default     = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
}

variable "master_instance_type" {
  description = "Instance type for the control-plane node"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root EBS volume size, GiB"
  type        = number
  default     = 20
}

variable "detailed_monitoring" {
  type    = bool
  default = false
}

variable "environment" {
  description = "environment type"
  type        = string
  default     = "development"
}

variable "admin_cidr_blocks" {
  description = <<-EOT
    CIDRs allowed to SSH (22) and reach the kube-apiserver (6443).
    No default on purpose — you must state who may administer the cluster.
    In CI it is set via TF_VAR_admin_cidr_blocks (your IP + the runner IP).
  EOT
  type        = list(string)

  validation {
    condition     = length(var.admin_cidr_blocks) > 0 && !contains(var.admin_cidr_blocks, "0.0.0.0/0")
    error_message = "admin_cidr_blocks must be non-empty and must not contain 0.0.0.0/0."
  }
}

variable "common_tag" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Owner   = "Pavel Malachovski"
    Project = "TeachMeSkills Diploma"
  }
}

variable "key_name" {
  description = "Name suffix of the generated EC2 key pair"
  type        = string
  default     = "k8s-key"
}
