variable "aws_region" {
    description = "The AWS region to use to create resources"
    default = "eu-central-1"
}

variable "allow_ports" {
    description = "List of ports to open on the server"
    default = ["22","80","443","8080"]
    type = list
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