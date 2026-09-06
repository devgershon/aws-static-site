variable "aws_region" {
  description = "Primary AWS region for S3 and other resources."
  type        = string
  default     = "eu-west-2" # London
}

variable "environment" {
  description = "Deployment environment label (e.g. prod, staging)."
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "My registered domain name will be here"
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket. Convention: domain-static-site." #But I not using a domain yet so put my name there
  type        = string
  default     = "devgershon-portfolio-static-site"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. PriceClass_100 covers North America + Europe (cheapest). PriceClass_All is global."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}
