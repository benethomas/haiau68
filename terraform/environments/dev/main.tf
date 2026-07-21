locals {
  common_tags = {
    Project     = "haiau68"
    Service     = "website"
    Environment = "Dev"
    ManagedBy   = "terraform"
  }
}

module "static_website" {
  source = "../../modules/static-website"

  environment = "dev"
  domain_name = "dev.haiau68.com"
  tags        = local.common_tags

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}