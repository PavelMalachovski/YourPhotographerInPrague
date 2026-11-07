variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket"
  type        = string
}

variable "github_repository" {
  description = "owner/repo allowed to assume the CI roles"
  type        = string
  default     = "PavelMalachovski/YourPhotographerInPrague"
}

variable "project_tag" {
  description = "Value of the Project tag on resources the apply role may destroy (must match common_tag.Project)"
  type        = string
  default     = "TeachMeSkills Diploma"
}
