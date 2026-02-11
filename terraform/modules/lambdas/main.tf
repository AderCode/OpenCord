# IAM execution role shared by all Lambdas
resource "aws_iam_role" "lambda_exec" {
  name = "opencord-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Project = "opencord"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "opencord-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:GetItem",
            "dynamodb:Query",
            "dynamodb:DeleteItem",
            "dynamodb:Scan",
          ]
          Resource = [
            var.messages_table_arn,
            "${var.messages_table_arn}/index/*",
            var.connections_table_arn,
            "${var.connections_table_arn}/index/*",
          ]
        },
        {
          Effect   = "Allow"
          Action   = "execute-api:ManageConnections"
          Resource = "arn:aws:execute-api:*:*:*/@connections/*"
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = "arn:aws:logs:*:*:*"
        },
      ],
      var.dynamodb_kms_key_arn != null ? [
        {
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:GenerateDataKey",
          ]
          Resource = var.dynamodb_kms_key_arn
        },
      ] : [],
    )
  })
}

# Zip Lambda source code
data "archive_file" "ws_connect" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/ws_connect"
  output_path = "${path.module}/../../../.build/ws_connect.zip"
}

data "archive_file" "ws_disconnect" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/ws_disconnect"
  output_path = "${path.module}/../../../.build/ws_disconnect.zip"
}

data "archive_file" "ws_default" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/ws_default"
  output_path = "${path.module}/../../../.build/ws_default.zip"
}

data "archive_file" "http_api" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/http_api"
  output_path = "${path.module}/../../../.build/http_api.zip"
}

data "archive_file" "ws_auth" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend/ws_auth"
  output_path = "${path.module}/../../../.build/ws_auth.zip"
}

# Lambda functions
resource "aws_lambda_function" "ws_connect" {
  function_name    = "opencord-ws-connect"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.ws_connect.output_path
  source_code_hash = data.archive_file.ws_connect.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      CONNECTIONS_TABLE = var.connections_table_name
    }
  }

  tags = {
    Project = "opencord"
  }
}

resource "aws_lambda_function" "ws_disconnect" {
  function_name    = "opencord-ws-disconnect"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.ws_disconnect.output_path
  source_code_hash = data.archive_file.ws_disconnect.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      CONNECTIONS_TABLE = var.connections_table_name
    }
  }

  tags = {
    Project = "opencord"
  }
}

resource "aws_lambda_function" "ws_default" {
  function_name    = "opencord-ws-default"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.ws_default.output_path
  source_code_hash = data.archive_file.ws_default.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      MESSAGES_TABLE    = var.messages_table_name
      CONNECTIONS_TABLE = var.connections_table_name
    }
  }

  tags = {
    Project = "opencord"
  }
}

resource "aws_lambda_function" "ws_auth" {
  function_name    = "opencord-ws-auth"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.ws_auth.output_path
  source_code_hash = data.archive_file.ws_auth.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
    }
  }

  tags = {
    Project = "opencord"
  }
}

resource "aws_lambda_function" "http_api" {
  function_name    = "opencord-http-api"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.http_api.output_path
  source_code_hash = data.archive_file.http_api.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      MESSAGES_TABLE = var.messages_table_name
    }
  }

  tags = {
    Project = "opencord"
  }
}
