📄 Instructions for AI Tooling — Self-Hosted AWS Terraform Stack
🧾 Overview

Generate Terraform code that:

Uses remote state in AWS S3 + DynamoDB for locking.

Provisions core services for a fully self-hosted Discord-like backend:

Cognito user pool + custom auth domain

API Gateway HTTP

API Gateway WebSocket

DynamoDB for messages/connections

Lambda functions for backend logic

S3 + CloudFront for static front/CDN

Automates DNS + ACM certificate provisioning via Route53.

Exposes predictable domain endpoints:

api.<base_domain>

ws.<base_domain>

auth.<base_domain>

cdn.<base_domain>

Outputs only the base domain; frontend can derive URLs from it (no AWS IDs required).

📌 Files to Generate

Create the following Terraform files:

backend.tf
variables.tf
providers.tf
main.tf
outputs.tf
modules/
dns/
acm/
cognito/
api_http/
api_ws/
lambdas/
s3_cloudfront/
dynamodb/
monitoring/

🧱 1. backend.tf — Remote State Setup (AWS S3 + DynamoDB)

Include a Terraform backend config similar to:

terraform {
backend "s3" {
bucket = var.state_bucket
key = "selfhosted/${var.base_domain}/terraform.tfstate"
region = var.aws_region
dynamodb_table = var.lock_table
encrypt = true
}
}

The bucket and lock table SHOULD be provisioned beforehand (or provide separate bootstrap instructions).
Remote state prevents collisions and enables team workflows.

⚙️ 2. providers.tf

Include AWS provider configuration:

provider "aws" {
region = var.aws_region
}

📋 3. variables.tf

Define required global variables:

variable "base_domain" {
description = "The root domain (e.g. example.chat)"
type = string
}

variable "aws_region" {
description = "AWS region"
type = string
default = "us-east-1"
}

variable "state_bucket" {
description = "S3 bucket for Terraform state"
type = string
}

variable "lock_table" {
description = "DynamoDB table name for state locking"
type = string
}

Add others as needed per module (e.g. lambda memory, DB read/write capacity, etc.).

🏷️ 4. modules/dns/ — Route53 Hosted Zone

Generate code that:

Looks up (or creates) a Route53 hosted zone for var.base_domain.

Outputs the zone ID.

You can use:

data "aws_route53_zone" "main" {
name = var.base_domain
private_zone = false
}

Use the zone ID in subsequent modules.

🔐 5. modules/acm/ — ACM Certificate with DNS Validation

Generate Terraform that uses the ACM module to request a certificate:

domain_name = var.base_domain

SANs: "api.${var.base_domain}", "ws.${var.base_domain}", "auth.${var.base_domain}", "cdn.${var.base_domain}"

Modules such as the community ACM registry module can handle validation.

Ensure wait_for_validation = true so Terraform waits for DNS to propagate.

🧠 6. modules/cognito/ — Cognito + Custom Domain

Create:

resource "aws_cognito_user_pool" "this" { ... }

resource "aws_cognito_user_pool_client" "app" { ... }

resource "aws_cognito_user_pool_domain" "custom" {
domain = "auth.${var.base_domain}"
user_pool_id = aws_cognito_user_pool.this.id
custom_domain_config {
certificate_arn = module.acm.acm_certificate_arn
}
}

Create a Route53 alias from auth.<base_domain> to the Cognito CloudFront domain.

Custom Auth domains must use ACM certs in us-east-1.

🌐 7. modules/api_http/ — API Gateway HTTP with Custom Domain

Use a Terraform AWS API Gateway v2 module (HTTP), set:

domain_name = "api.${var.base_domain}"

domain_name_certificate_arn = module.acm.acm_certificate_arn

CORS config allow origins from https://${var.base_domain}

Map a default stage and ensure a Route53 alias record points the subdomain to the API Gateway domain.

⚡ 8. modules/api_ws/ — WebSocket API + Custom Domain

Similarly provision API Gateway v2 for WebSockets:

protocol_type = "WEBSOCKET"

Route definitions such as $connect, sendMessage, etc.

Custom domain mapping to ws.${var.base_domain} with alias record.

🧪 9. modules/lambdas/ — Lambda Functions

Generate:

Message handling

Presence management

Auth verification (JWT from Cognito)

WebSocket lifecycle hooks ($connect, $disconnect)

Dynamic fan-out via API Gateway connection management

Include IAM role and policies granting:

DynamoDB access

API Gateway message posting

CloudWatch logs

🗄️ 10. modules/dynamodb/ — Messaging + Presence Tables

Define tables:

messages table with:

pk = channel

sk = timestamp

connections table with:

pk = channel

sk = connection_id

TTL attribute for presence

Use on-demand mode for cost-efficiency.

☁️ 11. modules/s3_cloudfront/ — Static Files + CDN

Provision:

S3 bucket (block public)

CloudFront distribution with:

Alias: cdn.<base_domain>

ACM certificate for TLS (same as others)

Create DNS alias record for CloudFront.

📊 12. monitoring/ — Optional Logging + Metrics

Add:

CloudWatch log groups

Alarms for errors / Lambda throttles

Optional WAF attachment

📤 Outputs.tf

Have outputs such as:

output "base_domain" {
value = var.base_domain
}

output "api_url" {
value = "https://api.${var.base_domain}"
}

output "ws_url" {
value = "wss://ws.${var.base_domain}"
}

output "auth_url" {
value = "https://auth.${var.base_domain}"
}

Frontend can derive all endpoints from base_domain.

📌 Important Implementation Notes

✅ ACM certificates must be validated by DNS for each domain/subdomain. Use Route53 DNS records automatically generated via Terraform.
✅ Custom domains for API Gateway must be mapped with base path mappings and Route53 alias records pointing to the API Gateway domain.
✅ Cognito custom domain certificates must be in us-east-1.
✅ WebSocket API Gateway custom domains are supported via API Gateway v2 modules.

🏁 User Instructions (Run Steps)

In the user’s AWS account:

Prepare Terraform bootstrap for remote state (S3 + DynamoDB).

Clone the repo.

Set:

export TF_VAR_base_domain="example.chat"
export TF_VAR_aws_region="us-east-1"
export TF_VAR_state_bucket="my-tf-state-bucket"
export TF_VAR_lock_table="tf-lock-table"

Run:

terraform init
terraform apply -auto-approve

The processing should create all infrastructure. Frontend only needs:

BASE_DOMAIN=example.chat
