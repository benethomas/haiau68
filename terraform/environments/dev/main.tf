module "static_website" {
  source = "../../modules/static-website"

  environment = "dev"
  domain_name = "dev.haiau68.com"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}