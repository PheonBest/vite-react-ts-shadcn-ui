# Output the FQDNs of the created Cloudflare records
output "validation_record_fqdns" {
  description = "The FQDNs of the Cloudflare validation records."
  value       = cloudflare_record.validation[*].hostname
}
