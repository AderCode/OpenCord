variable "base_domain" {
  description = "The root domain for the certificate"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID for DNS validation"
  type        = string
}
