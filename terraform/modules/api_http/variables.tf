variable "base_domain" {
  description = "Base domain"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Lambda invoke ARN for the HTTP API handler"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name for permission grant"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for JWT authorizer"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito App Client ID for JWT authorizer"
  type        = string
}

variable "cognito_user_pool_endpoint" {
  description = "Cognito User Pool endpoint (issuer URL)"
  type        = string
}
