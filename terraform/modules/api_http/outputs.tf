output "api_id" {
  description = "HTTP API Gateway ID"
  value       = aws_apigatewayv2_api.http.id
}

output "api_endpoint" {
  description = "HTTP API Gateway endpoint"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "execution_arn" {
  description = "HTTP API Gateway execution ARN"
  value       = aws_apigatewayv2_api.http.execution_arn
}
