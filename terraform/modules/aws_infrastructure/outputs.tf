output "my_instance_id" {
  value = aws_instance.my_amazon_linux_machine.id
}

output "aws_availability_zones" {
    value = data.aws_availability_zones.available
}

output "latest_linux_ami_id" {
  value = data.aws_ami.latest_amazon_linux.id
}

output "latest_linux_ami_name" {
  value = data.aws_ami.latest_amazon_linux.name
}

output "my_elastic_id" {
  value = aws_eip.my_static_ip.public_ip
}