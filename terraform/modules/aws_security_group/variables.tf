variable "public_ports" {
  description = "TCP ports open to the whole internet (web traffic only)"
  type        = list(number)
  default     = [80, 443]
}

variable "admin_ports" {
  description = "TCP ports reachable only from admin_cidr_blocks (SSH, kube-apiserver)"
  type        = list(number)
  default     = [22, 6443]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to reach admin_ports, e.g. [\"203.0.113.10/32\"]"
  type        = list(string)

  validation {
    condition     = length(var.admin_cidr_blocks) > 0 && !contains(var.admin_cidr_blocks, "0.0.0.0/0")
    error_message = "admin_cidr_blocks must be non-empty and must not contain 0.0.0.0/0."
  }

  validation {
    condition     = alltrue([for c in var.admin_cidr_blocks : can(cidrhost(c, 0))])
    error_message = "Every entry of admin_cidr_blocks must be a valid IPv4 CIDR."
  }
}

variable "environment" {
  description = "environment type"
  type        = string
  default     = "development"
}

variable "common_tag" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Owner   = "Pavel Malachovski"
    Project = "TeachMeSkills Diploma"
  }
}
