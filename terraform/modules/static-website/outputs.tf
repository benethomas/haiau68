output "website_bucket_name" {
  description = "Name of the S3 bucket for website content"
  value       = aws_s3_bucket.website.bucket
}