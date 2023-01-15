output "aws_availability_zones" {
    value = data.aws_availability_zones.available
}

output "latest_linux_ami_id" {
  value = data.aws_ami.latest_amazon_linux.id
}

output "latest_linux_ami_name" {
  value = data.aws_ami.latest_amazon_linux.name
}