variable "aws_region" {
    description = "The AWS region to use to create resources"
    default = "eu-central-1"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}


variable "public_subnet_cidrs" {
    default = [
        "10.0.1.0/24"
    ]
}

# variable "private_subnet_cidrs" {
#     default = []
# }

variable "environment" {
    default = "development"
}