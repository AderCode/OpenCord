resource "aws_cloudwatch_log_group" "lambda" {
  for_each = toset(var.lambda_function_names)

  name              = "/aws/lambda/${each.value}"
  retention_in_days = 14

  tags = {
    Project = "opencord"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "opencord-${each.value}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda errors for ${each.value}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  tags = {
    Project = "opencord"
  }
}

# Optional WAF
resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0

  name  = "opencord-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "opencord-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "opencord-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Project = "opencord"
  }
}
