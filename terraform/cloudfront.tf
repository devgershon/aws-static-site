# ──────────────────────────────────────────────
# CloudFront Distribution
# ──────────────────────────────────────────────
# CloudFront is a CDN (Content Delivery Network). It caches the site at
# AWS edge locations around the world so visitors get fast load times
# regardless of where they are. It also handles HTTPS termination.
# ──────────────────────────────────────────────

locals {
  s3_origin_id = "S3-${var.bucket_name}"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  comment             = "Portfolio static site — ${var.environment}"

  # Use a custom domain if provided, otherwise CloudFront gives you a free *.cloudfront.net URL.
  aliases = var.domain_name != "" ? [var.domain_name, "www.${var.domain_name}"] : []

  # ── Origin: private S3 bucket, accessed via OAC ──
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # ── Default cache behaviour ──
  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https" # HTTP requests are redirected to HTTPS

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Use AWS managed caching policy (recommended over legacy forward headers approach)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized

    compress = true # Gzip/Brotli compression — reduces transfer size
  }

  # ── Custom error pages ──
  # If S3 returns a 403 (object not found in private bucket), show the index.html.
  # This makes single-page apps work correctly for deep links.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # ── TLS / HTTPS ──
  viewer_certificate {
    # If we have a domain + certificate, use it. Otherwise use the default CloudFront cert.
    acm_certificate_arn      = var.domain_name != "" ? aws_acm_certificate_validation.site[0].certificate_arn : null
    cloudfront_default_certificate = var.domain_name == ""
    ssl_support_method       = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version = var.domain_name != "" ? "TLSv1.2_2021" : null
  }

  # ── Geo restrictions ──
  # None — site is available worldwide.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ── Logging (optional — uncomment to enable access logs) ──
  # logging_config {
  #   bucket          = aws_s3_bucket.logs.bucket_domain_name
  #   include_cookies = false
  #   prefix          = "cloudfront/"
  # }

  tags = {
    Name = "${var.bucket_name}-distribution"
  }

  # Wait for the certificate to be validated before creating the distribution.
  depends_on = [aws_acm_certificate_validation.site]
}
