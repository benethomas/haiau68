module "static_website" {
  source = "../../modules/static-website"

  environment = "prod"
  domain_name = "haiau68.com"
}