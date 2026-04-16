output "website_bucket_name" {
  value = module.static_website.website_bucket_name
}

output "cloudfront_distribution_id" {
  value = module.static_website.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  value = module.static_website.cloudfront_domain_name
}