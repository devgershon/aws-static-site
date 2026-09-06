# ──────────────────────────────────────────────
# Route53 DNS
# ──────────────────────────────────────────────
# This file only creates resources if var.domain_name is set.
# But obviously I'm not using a domain so I will skip this file entirely for now, will work on the entire project further
# at the *.cloudfront.net URL shown in outputs.tf.
# ──────────────────────────────────────────────


data "aws_route53_zone" "site" {
  count        = var.domain_name != "" ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# A record for the apex domain
resource "aws_route53_record" "apex" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.site[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# A record for www subdomain (www.devgershon.dev → CloudFront)
resource "aws_route53_record" "www" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.site[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
