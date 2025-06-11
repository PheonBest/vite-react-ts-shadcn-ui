terraform {
  source = "../../infrastructure-modules/s3"
}

// Declare root terragrunt file
// This sets up backend.tf and provider.tf
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  root_dir = dirname(find_in_parent_folders("root.hcl"))
}

inputs = {
  env             = "staging"
  enable_failover_s3 = false
  project         = "launchplate-react"
  html_source_dir = abspath("${local.root_dir}/../../web/dist/")
}
