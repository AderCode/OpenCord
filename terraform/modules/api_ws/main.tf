resource "aws_apigatewayv2_api" "ws" {
  name                       = "opencord-ws-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"

  tags = {
    Project = "opencord"
  }
}

# Integrations
resource "aws_apigatewayv2_integration" "connect" {
  api_id             = aws_apigatewayv2_api.ws.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.ws_connect_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id             = aws_apigatewayv2_api.ws.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.ws_disconnect_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "default" {
  api_id             = aws_apigatewayv2_api.ws.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.ws_default_invoke_arn
  integration_method = "POST"
}

# Authorizer
resource "aws_apigatewayv2_authorizer" "request" {
  api_id                     = aws_apigatewayv2_api.ws.id
  authorizer_type            = "REQUEST"
  authorizer_uri             = var.ws_auth_invoke_arn
  name                       = "ws-jwt-authorizer"
  identity_sources           = ["route.request.querystring.token"]
}

# Routes
resource "aws_apigatewayv2_route" "connect" {
  api_id             = aws_apigatewayv2_api.ws.id
  route_key          = "$connect"
  target             = "integrations/${aws_apigatewayv2_integration.connect.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.request.id
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.ws.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

resource "aws_apigatewayv2_route" "send_message" {
  api_id    = aws_apigatewayv2_api.ws.id
  route_key = "sendMessage"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.ws.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "production" {
  api_id      = aws_apigatewayv2_api.ws.id
  name        = "production"
  auto_deploy = true

  tags = {
    Project = "opencord"
  }
}

# Lambda permissions
resource "aws_lambda_permission" "ws_connect" {
  statement_id  = "AllowWSConnectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.ws_connect_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ws.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ws_disconnect" {
  statement_id  = "AllowWSDisconnectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.ws_disconnect_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ws.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ws_default" {
  statement_id  = "AllowWSDefaultInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.ws_default_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ws.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ws_auth" {
  statement_id  = "AllowWSAuthInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.ws_auth_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ws.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.request.id}"
}

# Custom domain
resource "aws_apigatewayv2_domain_name" "ws" {
  domain_name = "ws.${var.base_domain}"

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = {
    Project = "opencord"
  }
}

resource "aws_apigatewayv2_api_mapping" "ws" {
  api_id      = aws_apigatewayv2_api.ws.id
  domain_name = aws_apigatewayv2_domain_name.ws.id
  stage       = aws_apigatewayv2_stage.production.id
}

resource "aws_route53_record" "ws" {
  zone_id = var.zone_id
  name    = "ws.${var.base_domain}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.ws.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.ws.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
