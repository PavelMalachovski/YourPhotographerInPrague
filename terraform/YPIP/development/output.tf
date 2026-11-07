output "my_k8s_cluster_master_public_ip" {
  value = aws_eip.node["master"].public_ip
}
output "my_k8s_cluster_worker1_public_ip" {
  value = aws_eip.node["worker1"].public_ip
}
output "my_k8s_cluster_worker2_public_ip" {
  value = aws_eip.node["worker2"].public_ip
}
# The private key is intentionally NOT exposed as an output; it is written to
# key.pem (0400) by local_sensitive_file and kept in encrypted remote state.
