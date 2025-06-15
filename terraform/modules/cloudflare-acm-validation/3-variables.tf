# Input variables for this module
variable "cloudflare_zone_name" {
  description = "The name of the Cloudflare zone (e.g., example.com)."
  type        = string
}

variable "acm_validation_domains" {
  description = "List of validation domain details from the ACM module."
  type        = list(any)
}
