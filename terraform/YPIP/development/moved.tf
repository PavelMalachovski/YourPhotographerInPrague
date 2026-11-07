# Keep existing state addresses working after the refactor to for_each.
moved {
  from = aws_instance.my_k8s_cluster_master
  to   = aws_instance.node["master"]
}
moved {
  from = aws_instance.my_k8s_cluster_worker1
  to   = aws_instance.node["worker1"]
}
moved {
  from = aws_instance.my_k8s_cluster_worker2
  to   = aws_instance.node["worker2"]
}
moved {
  from = aws_eip.my_static_ip_master
  to   = aws_eip.node["master"]
}
moved {
  from = aws_eip.my_static_ip_worker1
  to   = aws_eip.node["worker1"]
}
moved {
  from = aws_eip.my_static_ip_worker2
  to   = aws_eip.node["worker2"]
}
