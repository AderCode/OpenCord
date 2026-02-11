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

variable "enable_kms_encryption" {
  description = "Use a customer-managed KMS key for S3 encryption at rest"
  type        = bool
  default     = false
}
