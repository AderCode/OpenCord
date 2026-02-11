variable "base_domain" {
  description = "Base domain for resource naming"
  type        = string
}

variable "messages_table_name" {
  description = "DynamoDB messages table name"
  type        = string
}

variable "messages_table_arn" {
  description = "DynamoDB messages table ARN"
  type        = string
}

variable "connections_table_name" {
  description = "DynamoDB connections table name"
  type        = string
}

variable "connections_table_arn" {
  description = "DynamoDB connections table ARN"
  type        = string
}

variable "dynamodb_kms_key_arn" {
  description = "ARN of the customer-managed KMS key for DynamoDB (null if KMS disabled)"
  type        = string
  default     = null
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for JWT verification"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito app client ID for JWT audience validation"
  type        = string
}
