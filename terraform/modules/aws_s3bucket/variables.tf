variable "bucket_name" {
  description = "Globally unique bucket name. Empty = <environment>-ypip-s3-bucket"
  type        = string
  default     = ""
}

variable "versioning" {
  type        = string
  description = "Versioning state (keep Enabled for Terraform state)"
  default     = "Enabled"
}

variable "environment" {
  description = "environment type"
  type        = string
  default     = "development"
}
