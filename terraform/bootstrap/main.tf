#=============================================================================
# Bootstrap (run once, locally, with admin credentials):
#   - S3 bucket for Terraform remote state (private, encrypted, versioned)
#   - GitHub Actions OIDC provider
#   - IAM role "plan"  : read-only, usable from any branch of this repo
#   - IAM role "apply" : deploy rights, usable ONLY from the protected
#                        GitHub environment "production"
#
# This replaces long-lived AWS access keys stored in GitHub Secrets.
#
#   cd terraform/bootstrap
#   terraform init && terraform apply -var state_bucket_name=<unique-name>
#=============================================================================

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "state_bucket" {
  source      = "../modules/aws_s3bucket"
  bucket_name = var.state_bucket_name
  versioning  = "Enabled"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

locals {
  oidc_sub_prefix = "repo:${var.github_repository}"
}

#----------------------------------------------------------------------------
# Trust policies
#----------------------------------------------------------------------------
data "aws_iam_policy_document" "trust_plan" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.oidc_sub_prefix}:ref:refs/heads/*"]
    }
  }
}

data "aws_iam_policy_document" "trust_apply" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    # Only jobs that run in the protected "production" environment
    # (required reviewers + master-only deployment branch rule).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.oidc_sub_prefix}:environment:production"]
    }
  }
}

#----------------------------------------------------------------------------
# State access
#----------------------------------------------------------------------------
data "aws_iam_policy_document" "state" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [module.state_bucket.s3_bucket_arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.state_bucket.s3_bucket_arn}/ypip/*"]
  }
}

resource "aws_iam_policy" "state" {
  name   = "ypip-terraform-state"
  policy = data.aws_iam_policy_document.state.json
}

#----------------------------------------------------------------------------
# Roles
#----------------------------------------------------------------------------
resource "aws_iam_role" "plan" {
  name               = "ypip-github-plan"
  assume_role_policy = data.aws_iam_policy_document.trust_plan.json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "plan_state" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.state.arn
}

resource "aws_iam_role" "apply" {
  name                 = "ypip-github-apply"
  assume_role_policy   = data.aws_iam_policy_document.trust_apply.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "apply_ec2" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "apply_state" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.state.arn
}
