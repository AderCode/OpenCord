output "api_id" {
  description = "WebSocket API Gateway ID"
  value       = aws_apigatewayv2_api.ws.id
}

output "api_endpoint" {
  description = "WebSocket API Gateway endpoint"
  value       = aws_apigatewayv2_api.ws.api_endpoint
}

output "execution_arn" {
  description = "WebSocket API Gateway execution ARN"
  value       = aws_apigatewayv2_api.ws.execution_arn
}
