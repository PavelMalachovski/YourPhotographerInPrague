output "s3_bucket_name" {
  value = aws_s3_bucket.my_s3_bucket.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.my_s3_bucket.arn
}

output "s3_bucket_region" {
  value = aws_s3_bucket.my_s3_bucket.region
}
