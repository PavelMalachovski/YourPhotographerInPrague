provider "github" {
    token = var.github_token
}

#=============================================================================
# Git push
#=============================================================================
# locals {
#   timestamp = "${timestamp()}"
#   timestamp_sanitized = "${replace("${local.timestamp}", "/[-| |T|Z|:]/", "")}"

# }

# resource "null_resource" "cmd" {
#     provisioner "local-exec" {
#         command = "echo Terraform apply started: ${local.timestamp_sanitized} >> project-run.log"
#     }
#     triggers = {
#         always_run = "${timestamp()}"
#     }
# }

# resource "null_resource" "git_add" {
#     provisioner "local-exec" {
#         command = "git add ."
#     }
#     triggers = {
#         always_run = "${timestamp()}"
#     }
# }

# resource "null_resource" "git_commit" {
#     provisioner "local-exec" {
#         command = "git commit -m 'start project ${local.timestamp_sanitized}'"
#     }
#     triggers = {
#         always_run = "${timestamp()}"
#     }
# }

# resource "null_resource" "git_push" {
#     provisioner "local-exec" {
#         command = "git push"
#     }
#     triggers = {
#         always_run = "${timestamp()}"
#     }
# }