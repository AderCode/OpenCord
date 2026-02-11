variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
}

variable "enable_waf" {
  description = "Whether to enable WAF"
  type        = bool
  default     = false
}

variable "api_gateway_arn" {
  description = "API Gateway ARN for WAF association (if enabled)"
  type        = string
  default     = ""
}
