resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for ${var.project_name}"
}

# Create policy to allow OAI to retrieve objects from S3 bucket
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
}
# Assign policy
resource "aws_s3_bucket_policy" "static_website_bucket_policy" {
  depends_on = [aws_s3_bucket.this, aws_s3_bucket_website_configuration.this]
  bucket     = aws_s3_bucket.this.id
  policy     = data.aws_iam_policy_document.s3_policy.json
}

# Setup cache with CloudFront distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  web_acl_id          = aws_wafv2_web_acl.this.arn
  default_root_object = var.index_document

  aliases = [var.domain_name, "www.${var.domain_name}", "*.${var.domain_name}"]

  viewer_certificate {
    acm_certificate_arn      = module.acm.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  dynamic "origin_group" {
    for_each = var.enable_failover_s3 ? [1] : []

    content {
      origin_id = "${var.project_name}-${var.env}-frontend-origin-group"

      failover_criteria {
        status_codes = [403, 404, 500, 502]
      }

      member {
        origin_id = "${var.project_name}-${var.env}-frontend-origin-primary"
      }

      member {
        origin_id = "${var.project_name}-${var.env}-frontend-origin-failover"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "${var.project_name}-${var.env}-frontend-origin-primary"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  dynamic "origin" {
    for_each = var.enable_failover_s3 ? [1] : []

    content {
      domain_name = aws_s3_bucket.failover["enabled"].bucket_regional_domain_name
      origin_id   = "${var.project_name}-${var.env}-frontend-origin-failover"

      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
      }

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.log_bucket.bucket_domain_name
    prefix          = "cloudfront/"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.enable_failover_s3 ? "${var.project_name}-${var.env}-frontend-origin-group" : "${var.project_name}-${var.env}-frontend-origin-primary"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    name        = "${var.env}-${var.project_name}"
    environment = var.env
    Project     = var.project_name
  }
}

# Invalidate cache when index.html hash change.
resource "null_resource" "invalidate_html" {
  triggers = {
    index_file_hash = filemd5("${var.html_source_dir}/${var.index_document}")
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.this.id} --paths /${var.index_document}"
  }

  depends_on = [aws_cloudfront_distribution.this]
}
