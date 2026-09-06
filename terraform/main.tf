terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # T0 run Terraform from any machine (including GitHub Actions).

#  backend "s3" {
#    bucket = "terraform-state-bucket"
#     key    = "static-site/terraform.tfstate"
#     region = "eu-west-2"
#   }
}

# Primary region for most resources
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-static-site"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ACM certificates for CloudFront MUST be in us-east-1
# second provider alias just for the certificate.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "aws-static-site"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
