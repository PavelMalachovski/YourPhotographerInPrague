output "state_bucket" {
  description = "Set as GitHub variable TF_STATE_BUCKET"
  value       = module.state_bucket.s3_bucket_name
}

output "plan_role_arn" {
  description = "Set as GitHub variable AWS_PLAN_ROLE_ARN"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Set as GitHub variable AWS_APPLY_ROLE_ARN (environment: production)"
  value       = aws_iam_role.apply.arn
}
