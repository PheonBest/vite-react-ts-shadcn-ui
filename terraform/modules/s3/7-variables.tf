variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "domain_name" {
  description = "The domain name - example.com"
  type        = string
}

variable "route53_zone_id" {
  description = "The Route53 zone ID"
  type        = string
}

variable "enable_failover_s3" {
  description = "If true, deploy a failover S3 bucket"
  type        = bool
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "index_document" {
  description = "The index document of the website"
  type        = string
  default     = "index.html"
}

variable "html_source_dir" {
  description = "Directory path for HTML source files"
  type        = string
  default     = "static/html/"
}
