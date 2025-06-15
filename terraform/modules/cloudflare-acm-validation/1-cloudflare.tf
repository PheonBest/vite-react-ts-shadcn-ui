# This Terraform configuration creates Cloudflare DNS records for ACM validation.

# Data source to get the Cloudflare zone details
# Assumes cloudflare_zone_name variable is provided to the module
data "cloudflare_zone" "this" {
  name = var.cloudflare_zone_name
}

# Create Cloudflare validation records
# This resource relies on the validation details output from the ACM module
resource "cloudflare_record" "validation" {
  count = length(var.acm_validation_domains) # Iterate based on ACM validation requirements

  zone_id = data.cloudflare_zone.this.id
  name    = element(var.acm_validation_domains, count.index)["resource_record_name"]
  type    = element(var.acm_validation_domains, count.index)["resource_record_type"]
  value   = trimsuffix(element(var.acm_validation_domains, count.index)["resource_record_value"], ".")
  ttl     = 60
  proxied = false

  allow_overwrite = true
}
