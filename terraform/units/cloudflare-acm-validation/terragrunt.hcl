include "root" {
	path   = find_in_parent_folders("root.hcl")
	expose = true
}

locals {
	parent_dir = get_parent_terragrunt_dir("root")
}

terraform {
	source = "${local.parent_dir}/modules/cloudflare-acm-validation"
}

# Define a dependency on the ACM unit
# This tells Terragrunt to apply the ACM unit before this one
dependency "acm" {
  # Replace with the actual path to your acm unit
  live_configs = "${get_parent_dir()}/acm"

  # Configure to extract the validation_domains output from the ACM unit
  # mock_outputs are needed for commands like init, validate, etc.
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "show", "destroy"]
  mock_outputs = {
    validation_domains = [] # Provide a sensible mock value (empty list)
  }
}

inputs = {
  # Pass required variables to the main.tf configuration
  cloudflare_zone_name = include.root.locals.cloudflare_zone_name
  # Get the validation_domains output from the ACM dependency
  acm_validation_domains = dependency.acm.outputs.validation_domains
}

# This unit should only be enabled if the dns_provider is 'cloudflare'
enabled = include.root.locals.dns_provider == "cloudflare"
