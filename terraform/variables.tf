variable "base_domain" {
  description = "The root domain (e.g. example.chat)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
}

# -----------------------------------------------------------------
# KMS encryption at rest
# -----------------------------------------------------------------
# When false (default), DynamoDB uses free AWS-owned keys and S3
# uses SSE-S3 (AES-256). Data is still encrypted at rest — you
# just cannot audit key usage, set rotation policies, or use
# grants/key policies for fine-grained access control.
#
# When true, a customer-managed KMS key is created for each
# storage layer (DynamoDB, S3). Additional costs:
#   - $1 / month per KMS key  (2 keys = $2 / month)
#   - $0.03 per 10,000 KMS API requests (encrypt/decrypt/
#     GenerateDataKey). Each DynamoDB read/write and each S3
#     GetObject/PutObject triggers a KMS call, so high-traffic
#     workloads may see meaningful API charges.
# -----------------------------------------------------------------
variable "enable_kms_encryption" {
  description = "Use customer-managed KMS keys for DynamoDB and S3 encryption at rest"
  type        = bool
  default     = false
}
