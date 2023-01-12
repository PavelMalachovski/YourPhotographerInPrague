provider "aws" {
    region = "eu-central-1"
}

module "aws_infrastructure_production" {
    source = "../modules/aws_infrastructure"
    instance_type = "t2.medium"
}

module "aws_s3bucket" {
    source = "../modules/aws_s3bucket"
    acl = "public-read-write"
    #tags = merge(var.common_tag, { Name = "${var.common_tag["Environment"]}-S3Bucket"})
}

module "aws_security_group" {
    source = "../modules/aws_security_group"
    acl = "public-read-write"
    tags = merge(var.common_tag, { Name = "${var.common_tag["Environment"]}-S3Bucket"})
}