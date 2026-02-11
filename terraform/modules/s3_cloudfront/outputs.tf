output "bucket_name" {
  description = "S3 bucket name for frontend assets"
  value       = aws_s3_bucket.frontend.id
}

output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "distribution_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}
