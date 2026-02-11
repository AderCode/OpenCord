variable "base_domain" {
  description = "Base domain, used for resource naming"
  type        = string
}

variable "enable_kms_encryption" {
  description = "Use a customer-managed KMS key for DynamoDB encryption at rest"
  type        = bool
  default     = false
}
