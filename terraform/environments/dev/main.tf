module "static_website" {
  source = "../../modules/static-website"

  environment = "dev"
  domain_name = "dev.haiau68.com"
}