output "cloudfront_url" {
  description = "site is live at this URL. Works even without a custom domain."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "custom_domain_url" {
  description = "my custom actual domain URL (only set if var.domain_name is configured)."
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "No custom domain configured"
}

output "s3_bucket_name" {
  description = "The S3 bucket name — used in the GitHub Actions deploy command."
  value       = aws_s3_bucket.site.bucket
}

output "cloudfront_distribution_id" {
  description = "The CloudFront distribution ID — used to create cache invalidations in CI/CD."
  value       = aws_cloudfront_distribution.site.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket (useful for IAM policies)."
  value       = aws_s3_bucket.site.arn
}
