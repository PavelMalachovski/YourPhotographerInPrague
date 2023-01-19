region = "eu-central-1"
owners = ["amazon"]
latest_amazon_linux = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
master_instance_type = "t2.small"
worker_instance_type = "t2.small"
detailed_monitoring = false
environment = "development"
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24"]
key_name = "key"
common_tag = {
    Owner = "Pavel Malachovski"
    Project = "TeachMeSkills Diploma"
}