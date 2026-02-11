output "log_group_names" {
  description = "CloudWatch log group names"
  value       = { for k, v in aws_cloudwatch_log_group.lambda : k => v.name }
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_errors : k => v.arn }
}
