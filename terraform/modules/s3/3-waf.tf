# Creates Access Control List to secure  CloudFront distribution

resource "aws_wafv2_web_acl" "this" {
  name        = "cloudfront-waf"
  description = "WAF for CloudFront serving S3 static website"
  scope       = "CLOUDFRONT" # Must be CLOUDFRONT for CloudFront distributions[6][8]
  provider    = aws.useast1

  default_action {
    allow {}
  }

  # Block malicious IP addresses
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  # Protect against common web exploits like SQL injection and XSS
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Protect against known bad inputs (e.g. malicious SQL, shell commands)
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Protect against anonymous IP
  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  # Protect against SQL Injection
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Protect against Linux Kernel Exploits
  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rate limit
  custom_response_body {
    key          = "blocked_request_custom_response"
    content      = "{\n    \"error\":\"Too Many Requests.\"\n}"
    content_type = "APPLICATION_JSON"
  }

  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {
        custom_response {
          custom_response_body_key = "blocked_request_custom_response"
          response_code            = 429
        }
      }
    }

    statement {

      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = 100
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }



  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    name        = "${var.env}-${var.project_name}"
    environment = var.env
    Project     = var.project_name
  }
}

# Add logging configuration to WAF
resource "aws_cloudwatch_log_group" "WafWebAclLoggroup" {
  name              = "${var.env}-${var.project_name}-aws-waf-logs-wafv2-web-acl"
  retention_in_days = 30
}

resource "aws_wafv2_web_acl_logging_configuration" "WafWebAclLogging" {
  log_destination_configs = [aws_cloudwatch_log_group.WafWebAclLoggroup.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
  depends_on = [
    aws_wafv2_web_acl.this,
    aws_cloudwatch_log_group.WafWebAclLoggroup
  ]
}
