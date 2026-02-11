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

variable "ws_connect_invoke_arn" {
  description = "Invoke ARN for ws_connect Lambda"
  type        = string
}

variable "ws_connect_function_name" {
  description = "Function name for ws_connect Lambda"
  type        = string
}

variable "ws_disconnect_invoke_arn" {
  description = "Invoke ARN for ws_disconnect Lambda"
  type        = string
}

variable "ws_disconnect_function_name" {
  description = "Function name for ws_disconnect Lambda"
  type        = string
}

variable "ws_default_invoke_arn" {
  description = "Invoke ARN for ws_default Lambda"
  type        = string
}

variable "ws_default_function_name" {
  description = "Function name for ws_default Lambda"
  type        = string
}

variable "ws_auth_invoke_arn" {
  description = "Invoke ARN for ws_auth Lambda authorizer"
  type        = string
}

variable "ws_auth_function_name" {
  description = "Function name for ws_auth Lambda authorizer"
  type        = string
}
