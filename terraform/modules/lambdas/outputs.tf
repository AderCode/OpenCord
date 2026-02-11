output "ws_connect_function_name" {
  value = aws_lambda_function.ws_connect.function_name
}

output "ws_connect_invoke_arn" {
  value = aws_lambda_function.ws_connect.invoke_arn
}

output "ws_disconnect_function_name" {
  value = aws_lambda_function.ws_disconnect.function_name
}

output "ws_disconnect_invoke_arn" {
  value = aws_lambda_function.ws_disconnect.invoke_arn
}

output "ws_default_function_name" {
  value = aws_lambda_function.ws_default.function_name
}

output "ws_default_invoke_arn" {
  value = aws_lambda_function.ws_default.invoke_arn
}

output "ws_auth_function_name" {
  value = aws_lambda_function.ws_auth.function_name
}

output "ws_auth_invoke_arn" {
  value = aws_lambda_function.ws_auth.invoke_arn
}

output "http_api_function_name" {
  value = aws_lambda_function.http_api.function_name
}

output "http_api_invoke_arn" {
  value = aws_lambda_function.http_api.invoke_arn
}

output "lambda_function_names" {
  description = "List of all Lambda function names for monitoring"
  value = [
    aws_lambda_function.ws_connect.function_name,
    aws_lambda_function.ws_disconnect.function_name,
    aws_lambda_function.ws_default.function_name,
    aws_lambda_function.ws_auth.function_name,
    aws_lambda_function.http_api.function_name,
  ]
}
