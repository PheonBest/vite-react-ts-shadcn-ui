# Primary origin bucket
resource "aws_s3_bucket" "this" {
  bucket        = "${var.env}-${var.project}"
  force_destroy = false

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/primary/"
  }
}

# Failover bucket with same logging config
resource "aws_s3_bucket" "failover" {
  bucket        = "${var.env}-${var.project}-failover"
  force_destroy = false

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/failover/"
  }
}

# Logging bucket and ACLs (unchanged)
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.env}-${var.project}-log"
}

resource "aws_s3_bucket_acl" "log_bucket" {
  acl    = "log-delivery-write"
  bucket = aws_s3_bucket.log_bucket.id
}

resource "aws_s3_bucket_public_access_block" "log_public_access" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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
  bucket = aws_s3_bucket.failover.id

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
  target_prefix = "log/"
}

# Bucket logging for failover bucket
resource "aws_s3_bucket_logging" "failover" {
  bucket        = aws_s3_bucket.failover.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
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
  bucket = aws_s3_bucket.failover.id

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
  for_each     = fileset(var.html_source_dir, "*")
  bucket       = aws_s3_bucket.failover.id
  key          = each.value
  source       = "${var.html_source_dir}/${each.value}"
  etag         = filemd5("${var.html_source_dir}/${each.value}")
  content_type = "text/html"
}
