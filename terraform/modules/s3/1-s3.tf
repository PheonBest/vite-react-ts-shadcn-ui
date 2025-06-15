# Primary origin bucket
resource "aws_s3_bucket" "this" {
  bucket        = "${var.env}-${var.project_name}"
  force_destroy = false

  tags = {
    name        = "${var.env}-${var.project_name}"
    environment = var.env
    Project     = var.project_name
  }
}
# Failover bucket
resource "aws_s3_bucket" "failover" {
  for_each = var.enable_failover_s3 ? { "enabled" = true } : {}

  bucket        = "${var.env}-${var.project_name}-failover"
  force_destroy = false

  tags = {
    name        = "${var.env}-${var.project_name}"
    environment = var.env
    Project     = var.project_name
  }
}
# Logging bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.env}-${var.project_name}-log"
}
# Set lifecycle configuration for log bucket
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "log_bucket_lifecycle"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
# Public access block for log bucket (same settings)
resource "aws_s3_bucket_public_access_block" "log_public_access" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Use bucket policy instead of ACLs to:
# - Allow S3 buckets to send logs
# - Allow Cloudflare to send logs
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn" = var.enable_failover_s3 ? [
              aws_s3_bucket.this.arn,
              aws_s3_bucket.failover["enabled"].arn
              ] : [
              aws_s3_bucket.this.arn
            ]
          }
        }
      }
    ]
  })
}

# Encryption
resource "aws_kms_key" "this" {
  is_enabled          = true
  enable_key_rotation = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "failover" {
  for_each = var.enable_failover_s3 ? { "enabled" = true } : {}

  bucket = aws_s3_bucket.failover["enabled"].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Bucket logging for primary bucket
resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/primary/"
}

# Bucket logging for failover bucket
resource "aws_s3_bucket_logging" "failover" {
  for_each = var.enable_failover_s3 ? { "enabled" = true } : {}

  bucket        = aws_s3_bucket.failover["enabled"].id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/failover/"
}

# Website config for primary bucket
resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.index_document
  }
}

# Public access block for primary bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Public access block for failover bucket (same settings)
resource "aws_s3_bucket_public_access_block" "failover_public_access" {
  for_each = var.enable_failover_s3 ? { "enabled" = true } : {}

  bucket = aws_s3_bucket.failover["enabled"].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload static files to primary bucket
resource "aws_s3_object" "static_site_upload_object" {
  for_each     = fileset(var.html_source_dir, "*")
  bucket       = aws_s3_bucket.this.id
  key          = each.value
  source       = "${var.html_source_dir}/${each.value}"
  etag         = filemd5("${var.html_source_dir}/${each.value}")
  content_type = "text/html"
}

# Upload same static files to failover bucket
resource "aws_s3_object" "static_site_upload_object_failover" {
  for_each = var.enable_failover_s3 ? { for file in fileset(var.html_source_dir, "*") : file => file } : {}

  bucket       = aws_s3_bucket.failover["enabled"].id
  key          = each.key
  source       = "${var.html_source_dir}/${each.key}"
  etag         = filemd5("${var.html_source_dir}/${each.key}")
  content_type = "text/html"
}
