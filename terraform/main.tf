# Foundation — no dependencies
module "dns" {
  source      = "./modules/dns"
  base_domain = var.base_domain
}

module "dynamodb" {
  source                = "./modules/dynamodb"
  base_domain           = var.base_domain
  enable_kms_encryption = var.enable_kms_encryption
}

# Certificate — depends on dns
module "acm" {
  source      = "./modules/acm"
  base_domain = var.base_domain
  zone_id     = module.dns.zone_id
}

# Cognito — depends on acm, dns
module "cognito" {
  source          = "./modules/cognito"
  base_domain     = var.base_domain
  certificate_arn = module.acm.certificate_arn
  zone_id         = module.dns.zone_id
  owner_email     = var.owner_email
  owner_password  = var.owner_password
}

# Lambdas — depends on dynamodb, cognito
module "lambdas" {
  source                 = "./modules/lambdas"
  base_domain            = var.base_domain
  messages_table_name    = module.dynamodb.messages_table_name
  messages_table_arn     = module.dynamodb.messages_table_arn
  connections_table_name = module.dynamodb.connections_table_name
  connections_table_arn  = module.dynamodb.connections_table_arn
  dynamodb_kms_key_arn   = module.dynamodb.kms_key_arn
  cognito_user_pool_id   = module.cognito.user_pool_id
  cognito_client_id      = module.cognito.client_id
}

# HTTP API — depends on acm, dns, lambdas, cognito
module "api_http" {
  source                     = "./modules/api_http"
  base_domain                = var.base_domain
  certificate_arn            = module.acm.certificate_arn
  zone_id                    = module.dns.zone_id
  lambda_invoke_arn          = module.lambdas.http_api_invoke_arn
  lambda_function_name       = module.lambdas.http_api_function_name
  cognito_user_pool_id       = module.cognito.user_pool_id
  cognito_client_id          = module.cognito.client_id
  cognito_user_pool_endpoint = module.cognito.user_pool_endpoint
}

# WebSocket API — depends on acm, dns, lambdas
module "api_ws" {
  source                      = "./modules/api_ws"
  base_domain                 = var.base_domain
  certificate_arn             = module.acm.certificate_arn
  zone_id                     = module.dns.zone_id
  ws_connect_invoke_arn       = module.lambdas.ws_connect_invoke_arn
  ws_connect_function_name    = module.lambdas.ws_connect_function_name
  ws_disconnect_invoke_arn    = module.lambdas.ws_disconnect_invoke_arn
  ws_disconnect_function_name = module.lambdas.ws_disconnect_function_name
  ws_default_invoke_arn       = module.lambdas.ws_default_invoke_arn
  ws_default_function_name    = module.lambdas.ws_default_function_name
  ws_auth_invoke_arn          = module.lambdas.ws_auth_invoke_arn
  ws_auth_function_name       = module.lambdas.ws_auth_function_name
}

# S3 + CloudFront — depends on acm, dns
module "s3_cloudfront" {
  source                = "./modules/s3_cloudfront"
  base_domain           = var.base_domain
  certificate_arn       = module.acm.certificate_arn
  zone_id               = module.dns.zone_id
  enable_kms_encryption = var.enable_kms_encryption
}

# Monitoring — depends on lambdas
module "monitoring" {
  source                = "./modules/monitoring"
  lambda_function_names = module.lambdas.lambda_function_names
}
