region               = "eu-central-1"
master_instance_type = "t3.small"
worker_instance_type = "t3.small"
detailed_monitoring  = false
environment          = "development"
key_name             = "k8s-key"
common_tag = {
  Owner   = "Pavel Malachovski"
  Project = "TeachMeSkills Diploma"
}
# admin_cidr_blocks is intentionally not set here — pass it via
# TF_VAR_admin_cidr_blocks='["<your-ip>/32"]' so your IP is not committed.
