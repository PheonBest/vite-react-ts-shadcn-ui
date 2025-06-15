# Include the root terragrunt.hcl configuration
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# Read environment-specific variables from environment.yml
locals {
  environment_vars = read_terragrunt_config("environment.yml")
  locals = merge(
    local.environment_vars.locals
  )
  root_dir         = dirname(find_in_parent_folders("root.hcl"))

  # Variable to control the DNS provider
  dns_provider = "cloudflare" # Set to "route53" or "cloudflare"
}

# Define inputs that are passed down to the modules included in this stack
inputs = merge(
  include.root.inputs,
  local.locals,
)

unit "acm" {
  source = "${input.root_dir}/units/acm"
  path   = "acm"

  values = {
    create_route53_records = dns_provider == "route53"
    validation_record_fqdns = [
       cloudflare_record.validation[*].hostname
    ]

    domain_name            = input.domain_name
    zone_id                = input.zone_id

    validation_method = "DNS"

    subject_alternative_names = ["*.${input.base_domain}"]

    wait_for_validation = true

    tags = {
      Name = "${input.project_name}-${input.environment}"
    }
  }
}

unit "cloudflare-acm-validation" {
  source = "${input.root_dir}/units/cloudflare-acm-validation"
  path   = "cloudflare-acm-validation"

  values = {
    domain_name = input.domain_name
    zone_id     = input.zone_id
  }
}

unit "s3" {
  source = "${input.root_dir}/units/s3"
  path   = "s3"

  values = {
    environment        = input.environment
    enable_failover_s3 = false
    project         = "launchplate-react"
    aws_region      = input.aws_region
    html_source_dir = abspath("${input.root_dir}/../web/dist/")
  }
}
