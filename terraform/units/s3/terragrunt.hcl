include "root" {
	path   = find_in_parent_folders("root.hcl")
	expose = true
}

locals {
	parent_dir = get_parent_terragrunt_dir("root")
}

terraform {
	source = "${local.parent_dir}/modules/s3"
}

dependency "acm" {
  config_path = "../acm"

  # Mock outputs allow us to continue to plan on the apply of the api module
	# even though the db module has not yet been applied.
	mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
	mock_outputs = {
		arn  = "arn:aws:acm:us-west-2:123456789012:certificate/mock-certificate"
		domain_validation_options = [
			{
				domain_name = "example.com"
				route53_zone_id = "Z123456789012345678"
			}
		]
		id = "mock-id"
		validation_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/mock-certificate"
		validation_id = "mock-validation-id"
	}
}

inputs = {
  aws_region = include.root.locals.aws_region
  env = include.root.locals.env
  project_name = include.root.locals.project_name
  domain_name = include.root.locals.domain_name
}
