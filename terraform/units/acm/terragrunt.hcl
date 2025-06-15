include "root" {
	path   = find_in_parent_folders("root.hcl")
	expose = true
}

terraform {
	source = "terraform-aws-modules/acm/aws"
}

inputs = {
  # Removing trailing dot from domain - just to be sure :)
  domain_name                       = trimsuffix(include.root.locals.base_domain, ".")
  zone_id                           = include.root.locals.zone_id
  validation_method = include.root.locals.validation_method
  validation_record_fqdns = include.root.locals.validation_record_fqdns
  wait_for_validation = include.root.locals.wait_for_validation
  subject_alternative_names         = ["*.${include.root.locals.base_domain}"]
  tags                              = include.root.locals.tags
}
