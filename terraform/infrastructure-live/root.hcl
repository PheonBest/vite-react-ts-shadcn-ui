# Deploys app

locals {
  region = "eu-west-3"
  # AWS WAF is available globally for CloudFront distributions, but you must use the Region US East (N. Virginia) to create your web ACL and any resources used in the web ACL, such as rule groups, IP sets, and regex pattern sets. Some interfaces offer a region choice of "Global (CloudFront)". Choosing this is identical to choosing Region US East (N. Virginia) or "us-east-1".
  cloudflareWAFRegion = "us-east-1"
}

# Generate backend.tf, which references backend remote state
# Use one S3 bucket across all environments,
# but partition by key (folder path)
remote_state {
  backend = "s3"

  config = {
    bucket = "tfstate-live--${get_aws_account_id()}"
    # store remote state at a different key using path_relative_to_include
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "${local.region}"
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

# Generate provider.tf
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
    region="${local.region}"
}
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}
EOF
}

inputs = {
  aws_region = local.region
}
