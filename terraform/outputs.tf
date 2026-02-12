output "base_domain" {
  description = "Base domain for all services"
  value       = var.base_domain
}

output "api_url" {
  description = "REST API endpoint"
  value       = "https://api.${var.base_domain}"
}

output "ws_url" {
  description = "WebSocket endpoint"
  value       = "wss://ws.${var.base_domain}"
}

output "auth_url" {
  description = "Cognito auth endpoint"
  value       = "https://auth.${var.base_domain}"
}

output "cdn_url" {
  description = "CDN / frontend endpoint"
  value       = "https://cdn.${var.base_domain}"
}

output "cognito_client_id" {
  description = "Cognito app client ID (needed for frontend)"
  value       = module.cognito.client_id
}

output "frontend_bucket" {
  description = "S3 bucket name for frontend assets"
  value       = module.s3_cloudfront.bucket_name
}
