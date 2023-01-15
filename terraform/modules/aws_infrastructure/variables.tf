variable "region" {
  description = "Please enter AWS region to deploy server"
  default = "eu-central-1"
  type = string
}

variable "owners" {
    default = ["amazon"]
    type = list
}

variable "latest_amazon_linux" {
    type = list
    default = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
}

variable "master_instance_type" {
    description = "Enter Instance TYpe"
    default = "t2.medium"
    type = string
}

variable "worker_instance_type" {
    description = "Enter Instance TYpe"
    default = "t2.micro"
    type = string
}

variable "detailed_monitoring" {
    default = false
    type = bool
}

variable "environment" {
    description = "environment type"
    default = "development"
}

variable "common_tag" {
    description = "Common tags to apply to all resources"
    type = map
    default = {
        Owner = "Pavel Malachovski"
        Project = "TeachMeSkills Diploma"
    }
}