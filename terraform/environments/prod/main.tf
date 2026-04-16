module "static_website" {
  source = "../../modules/static-website"

  environment = "prod"
  domain_name = "haiau68.com"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}