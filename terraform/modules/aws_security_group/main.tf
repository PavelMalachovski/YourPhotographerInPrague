#=============================================================================
# Security group for the k8s nodes
#
# * Public web ports (80/443) are open to the internet.
# * Administrative ports (SSH, kube-apiserver) are restricted to
#   var.admin_cidr_blocks — never 0.0.0.0/0.
# * Node-to-node traffic (etcd, kubelet, CNI, NodePorts…) is allowed only
#   between members of this same security group.
#=============================================================================

resource "aws_security_group" "my_sg" {
  name        = "${var.environment}-k8s-nodes"
  description = "k8s nodes: public web, restricted admin, intra-cluster"

  tags = merge(var.common_tag, { Name = "${var.environment} k8s nodes" })
}

resource "aws_vpc_security_group_ingress_rule" "public" {
  for_each = toset([for p in var.public_ports : tostring(p)])

  security_group_id = aws_security_group.my_sg.id
  description       = "Public web traffic on port ${each.value}"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "admin" {
  for_each = {
    for pair in setproduct([for p in var.admin_ports : tostring(p)], var.admin_cidr_blocks) :
    "${pair[0]}-${pair[1]}" => { port = tonumber(pair[0]), cidr = pair[1] }
  }

  security_group_id = aws_security_group.my_sg.id
  description       = "Admin access on port ${each.value.port} from ${each.value.cidr}"
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
}

resource "aws_vpc_security_group_ingress_rule" "intra_cluster" {
  security_group_id            = aws_security_group.my_sg.id
  description                  = "All traffic between cluster nodes"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.my_sg.id
}

# Nodes need outbound internet for apt, container images and kubespray.
resource "aws_vpc_security_group_egress_rule" "all" {
  #checkov:skip=CKV_AWS_382:Nodes must reach package mirrors and container registries
  security_group_id = aws_security_group.my_sg.id
  description       = "Outbound internet (apt, container registries)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
