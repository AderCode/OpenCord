output "messages_table_name" {
  description = "Name of the messages DynamoDB table"
  value       = aws_dynamodb_table.messages.name
}

output "messages_table_arn" {
  description = "ARN of the messages DynamoDB table"
  value       = aws_dynamodb_table.messages.arn
}

output "connections_table_name" {
  description = "Name of the connections DynamoDB table"
  value       = aws_dynamodb_table.connections.name
}

output "connections_table_arn" {
  description = "ARN of the connections DynamoDB table"
  value       = aws_dynamodb_table.connections.arn
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key for DynamoDB (null if KMS disabled)"
  value       = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
}
