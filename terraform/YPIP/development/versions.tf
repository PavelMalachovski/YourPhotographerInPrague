terraform {
  # >= 1.10 for native S3 state locking (use_lockfile)
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # Remote, encrypted, versioned state. The state contains the generated SSH
  # private key, so it must never live on a CI runner or in git.
  # Bucket is supplied at init time:
  #   terraform init -backend-config=backend.hcl        (local, see backend.hcl.example)
  #   terraform init -backend-config="bucket=$TF_STATE_BUCKET"   (CI)
  backend "s3" {
    key          = "ypip/development/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
