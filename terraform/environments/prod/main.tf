locals {
  common_tags = {
    Project     = "haiau68"
    Service     = "website"
    Environment = "Prod"
    ManagedBy   = "terraform"
  }
}

module "static_website" {
  source = "../../modules/static-website"

  environment = "prod"
  domain_name = "haiau68.com"
  tags        = local.common_tags

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}