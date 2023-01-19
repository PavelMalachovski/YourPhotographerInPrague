output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}

output "my_k8s_cluster_master_public_ip" {
  value = aws_eip.my_static_ip_master.public_ip
}
output "my_k8s_cluster_worker1_public_ip" {
  value = aws_eip.my_static_ip_worker1.public_ip
}
output "my_k8s_cluster_worker2_public_ip" {
  value = aws_eip.my_static_ip_worker2.public_ip
}
