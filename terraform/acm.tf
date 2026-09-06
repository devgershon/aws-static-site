# ──────────────────────────────────────────────
# ACM TLS Certificate
# ──────────────────────────────────────────────
# IMPORTANT: CloudFront requires its certificate to be in us-east-1 (N. Virginia),
# regardless of where other resources live. I used the `aws.us_east_1` provider
# alias defined in main.tf for this resource only.
# ──────────────────────────────────────────────

resource "aws_acm_certificate" "site" {
  # no domain name is I didnt create the certificate
  count = var.domain_name != "" ? 1 : 0

  provider          = aws.us_east_1
  domain_name       = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method = "DNS"

  lifecycle {
    # Create the new certificate before destroying the old one during renewals.
    # This prevents any downtime on the site.
    create_before_destroy = true
  }
}

# ──────────────────────────────────────────────
# DNS Validation Records
# ──────────────────────────────────────────────
# ACM needs to verify the ownership of the domain before it issues the certificate.
# It does this by checking for specific DNS records. I create those records
# in Route53 automatically. ACM then polls for them and issues the certificate.

resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.site[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = data.aws_route53_zone.site[0].zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Wait until ACM has actually issued the certificate before referencing it in CloudFront.
resource "aws_acm_certificate_validation" "site" {
  count = var.domain_name != "" ? 1 : 0

  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
