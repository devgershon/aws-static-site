# ──────────────────────────────────────────────
# S3 Bucket
# ──────────────────────────────────────────────
# The bucket is kept PRIVATE. Only CloudFront can read from it
# via the Origin Access Control (OAC) policy below.
# Direct public access is blocked — visitors must go through CloudFront.
# ──────────────────────────────────────────────

resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name

  # Prevent accidental deletion of the bucket (and the site) via Terraform.
  # Set to false if you want `terraform destroy` to remove the bucket.
  lifecycle {
    prevent_destroy = false
  }
}

# Block ALL public access — CloudFront uses OAC, not a public bucket policy.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning so you can roll back to any previous deployment.
resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption at rest (free with S3-managed keys).
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Tell S3 which file to serve as the root document.
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document { suffix = "index.html" }
  error_document { key    = "index.html" } # SPA-friendly: let the app handle 404s
}

# ──────────────────────────────────────────────
# Origin Access Control (OAC)
# ──────────────────────────────────────────────
# OAC is the modern replacement for Origin Access Identity (OAI).
# It lets CloudFront authenticate itself to the private S3 bucket.

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name} — allows CloudFront to read the private S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ──────────────────────────────────────────────
# Bucket Policy — allow only CloudFront (via OAC) to read objects
# ──────────────────────────────────────────────
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.s3_cloudfront.json

  # The CloudFront distribution must exist before its ARN can be referenced here.
  depends_on = [aws_cloudfront_distribution.site]
}

data "aws_iam_policy_document" "s3_cloudfront" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}
