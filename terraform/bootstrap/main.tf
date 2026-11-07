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

# Least-privilege deploy policy: only the EC2 actions the development stack
# uses, only in var.region, and destructive actions only on resources that
# carry this project's tag.
data "aws_iam_policy_document" "apply_ec2" {
  #checkov:skip=CKV_AWS_356:EC2 Describe* actions do not support resource-level permissions; all mutating actions are scoped
  statement {
    sid       = "ReadOnly"
    actions   = ["ec2:Describe*", "ec2:GetDefaultCreditSpecification"]
    resources = ["*"]
  }

  statement {
    sid = "CreateAndConfigure"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:CreateSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:ModifySecurityGroupRules",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:ImportKeyPair",
      "ec2:AllocateAddress",
      "ec2:AssociateAddress",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:StartInstances",
      "ec2:StopInstances",
    ]
    resources = local.ec2_resources
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }

  statement {
    sid = "DestroyOnlyProjectResources"
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteSecurityGroup",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteTags",
      "ec2:DisassociateAddress",
      "ec2:ReleaseAddress",
    ]
    resources = local.ec2_resources
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_tag]
    }
  }

  # Key pairs are named "<environment>-k8s-key"; restrict deletion by name.
  statement {
    sid       = "DeleteProjectKeyPair"
    actions   = ["ec2:DeleteKeyPair"]
    resources = ["arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:key-pair/*-k8s-key"]
  }
}

data "aws_caller_identity" "current" {}

locals {
  # Every EC2 resource of this account in var.region, plus public AMIs
  # (RunInstances needs read access to the image ARN).
  ec2_resources = [
    "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:*",
    "arn:aws:ec2:${var.region}::image/*",
  ]
}

resource "aws_iam_policy" "apply_ec2" {
  name   = "ypip-terraform-apply-ec2"
  policy = data.aws_iam_policy_document.apply_ec2.json
}

resource "aws_iam_role_policy_attachment" "apply_ec2" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.apply_ec2.arn
}

resource "aws_iam_role_policy_attachment" "apply_state" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.state.arn
}
