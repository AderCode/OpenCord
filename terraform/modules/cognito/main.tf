resource "aws_cognito_user_pool" "this" {
  name = "opencord-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  tags = {
    Project = "opencord"
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name         = "opencord-spa"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  supported_identity_providers = ["COGNITO"]

  callback_urls = [
    "https://cdn.${var.base_domain}",
    "https://cdn.${var.base_domain}/callback",
  ]

  logout_urls = [
    "https://cdn.${var.base_domain}",
  ]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true
}

resource "aws_cognito_user_pool_domain" "custom" {
  domain       = "auth.${var.base_domain}"
  user_pool_id = aws_cognito_user_pool.this.id

  certificate_arn = var.certificate_arn
}

resource "aws_route53_record" "auth" {
  zone_id = var.zone_id
  name    = "auth.${var.base_domain}"
  type    = "A"

  alias {
    name                   = aws_cognito_user_pool_domain.custom.cloudfront_distribution_arn
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID (global)
    evaluate_target_health = false
  }
}
