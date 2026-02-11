variable "base_domain" {
  description = "Base domain"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the custom domain"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}
