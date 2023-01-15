provider "aws" {
    region = "eu-central-1"
}

module "aws_infrastructure_development" {
    source = "../../modules/aws_infrastructure"
    master_instance_type = "t2.medium"
    worker_instance_type = "t2.micro"
}

module "aws_s3bucket" {
    source = "../../modules/aws_s3bucket"
    acl = "public-read-write"
}

module "aws_security_group" {
    source = "../../modules/aws_security_group"
    allow_ports = ["22","80","443","8080","1541","9092"]
}