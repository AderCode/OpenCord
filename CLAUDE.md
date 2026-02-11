# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenCord is an open-source, self-hosted Discord-like community platform supporting chat, video, and voice. It uses a serverless AWS architecture deployed via Terraform.

## Repository Structure

- `frontend/` — Static web application (deployed to S3 + CloudFront)
- `backend/` — Lambda functions for API and WebSocket handling
- `terraform/` — Infrastructure as Code for the full AWS stack

## Architecture

The system is fully serverless on AWS with four public endpoints derived from a single `base_domain`:

| Endpoint | Service | Purpose |
|---|---|---|
| `api.<base_domain>` | API Gateway HTTP (v2) | REST API |
| `ws.<base_domain>` | API Gateway WebSocket (v2) | Real-time messaging |
| `auth.<base_domain>` | Cognito custom domain | User authentication |
| `cdn.<base_domain>` | CloudFront + S3 | Static frontend assets |

**Key design decisions:**
- Frontend derives all endpoint URLs from `BASE_DOMAIN` alone — no AWS resource IDs are exposed
- DynamoDB tables: `messages` (PK: channel, SK: timestamp) and `connections` (PK: channel, SK: connection_id with TTL for presence)
- Lambda functions handle: message CRUD, presence management, JWT verification (via Cognito), WebSocket lifecycle ($connect/$disconnect), and dynamic fan-out
- ACM certificates must be in us-east-1 (required for Cognito custom domains and CloudFront)
- Remote Terraform state uses S3 + DynamoDB for locking

## Terraform Commands

```bash
# Set required environment variables
export TF_VAR_base_domain="example.chat"
export TF_VAR_aws_region="us-east-1"
export TF_VAR_state_bucket="my-tf-state-bucket"
export TF_VAR_lock_table="tf-lock-table"

# Deploy (from terraform/ directory)
terraform init
terraform apply
```

The S3 state bucket and DynamoDB lock table must be provisioned beforehand (bootstrap step).

## Terraform Module Layout

The `terraform/` directory should contain these modules:

`dns/` (Route53) → `acm/` (SSL certs with DNS validation) → `cognito/`, `api_http/`, `api_ws/`, `s3_cloudfront/` → `lambdas/` → `dynamodb/` → `monitoring/` (CloudWatch, WAF)

Modules depend on `dns` and `acm` outputs (zone ID, certificate ARN) for custom domain setup.

## Detailed Infrastructure Spec

See `.claude/INSTRUCTIONS.md` for the full Terraform generation specification including exact resource configurations, module interfaces, and IAM policies.
