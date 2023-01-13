variable "aws_region" {
    description = "The AWS region to use to create resources"
    default = "eu-central-1"
}

variable "versioning" {
    type = string
    description = "A state of versioning"
    default = "Disabled"
}

variable "acl" {
    type = string
    description = "defaults to private"
    default = "private"
}

variable "environment" {
    description = "environment type"
    default = "development"
}