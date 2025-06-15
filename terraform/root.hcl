# Deploys app

# GLOBAL PARAMETERS
locals {
  project_name = "launchplate-react"
  aws_region = "eu-west-3"
}

# Assume role through OIDC
# iam_role = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
# iam_web_identity_token = get_env("AN_OIDC_TOKEN")

# Scaffold templates
# List components available for scaffolding using "terragrunt catalog"
catalog {
  urls = [
    "https://github.com/gruntwork-io/terragrunt-infrastructure-catalog-example",
    "https://github.com/gruntwork-io/terraform-aws-utilities",
    "https://github.com/gruntwork-io/terraform-kubernetes-namespace"
  ]
}

# Configure Terragrunt to automatically store tfstate files in a single S3 bucket
# Key-partitioning ensures each environment has its own subfolder
remote_state {
  backend = "s3"

  config = {
    bucket = "tfstate-live--${get_aws_account_id()}"
    # store remote state at a different key using path_relative_to_include
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "${local.aws_region}"
    # Enable SSE-S3 encryption with Amazon-managed keys
    encrypt = true
    # Acquire a lock in DynamoDB while TF apply & destroy
    dynamodb_table = "tfstate-locks"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
    region="${local.aws_region}"

    default_tags {
        tags = {
          project     = "${local.project_name}"
          managedby   = "terraform"
        }
      }
}

# CloudFront can only be deployed in us-east-1, even though CloudFront is a global service.
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"

  default_tags {
      tags = {
        project     = "${local.project_name}"
        managedby   = "terraform"
      }
    }
}
EOF
}
