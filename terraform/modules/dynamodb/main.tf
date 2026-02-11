resource "aws_kms_key" "dynamodb" {
  count               = var.enable_kms_encryption ? 1 : 0
  description         = "Customer-managed key for OpenCord DynamoDB tables"
  enable_key_rotation = true

  tags = {
    Project = "opencord"
  }
}

resource "aws_kms_alias" "dynamodb" {
  count         = var.enable_kms_encryption ? 1 : 0
  name          = "alias/opencord-dynamodb"
  target_key_id = aws_kms_key.dynamodb[0].key_id
}

resource "aws_dynamodb_table" "messages" {
  name         = "opencord-messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "channel"
  range_key    = "timestamp"

  attribute {
    name = "channel"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  server_side_encryption {
    enabled     = var.enable_kms_encryption
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  tags = {
    Project = "opencord"
    Domain  = var.base_domain
  }
}

resource "aws_dynamodb_table" "connections" {
  name         = "opencord-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "channel"
  range_key    = "connection_id"

  attribute {
    name = "channel"
    type = "S"
  }

  attribute {
    name = "connection_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = "connection_id-index"
    hash_key        = "connection_id"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = var.enable_kms_encryption
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.dynamodb[0].arn : null
  }

  tags = {
    Project = "opencord"
    Domain  = var.base_domain
  }
}
