provider "aws" {
    region = var.aws_region
}

resource "aws_security_group" "my_sg" {
    name        = "${var.environment} Security group"
    description = "Dynamic Security Group"

    dynamic "ingress" {
    for_each = var.allow_ports
        content {
            description      = "TLS from VPC"
            from_port        = ingress.value
            to_port          = ingress.value
            protocol         = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }

    ingress {

        description      = "echo request"
        from_port        = -1
        to_port          = -1
        protocol         = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
        
    }

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }

    tags = merge(var.common_tag, { Name = "${var.environment} Security group"})
}
#=============================================================================