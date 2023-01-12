provider "aws" {
    region = var.aws_region
}

resource "aws_s3_bucket" "my_s3_bucket" {
    bucket = "${var.environment}-ypip-s3-bucket"
}

resource "aws_s3_bucket_acl" "my_s3_bucket_acl" {
    bucket = aws_s3_bucket.my_s3_bucket.id
    acl    = var.acl
}

resource "aws_s3_bucket_versioning" "versioning_example" {
    bucket = aws_s3_bucket.my_s3_bucket.id
    versioning_configuration {
        status = var.versioning
    }
}