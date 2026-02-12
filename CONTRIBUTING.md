# Contributing to OpenCord

Thanks for your interest in contributing to OpenCord! This guide will help you get started.

## Getting Started

1. Fork the repository and clone your fork
2. Create a new branch from `dev` for your work
3. Make your changes
4. Submit a pull request back to `dev`

## Prerequisites

- **Node.js** (v18+)
- **Terraform** (v1.0+)
- **AWS CLI** configured with valid credentials
- An AWS account with permissions to deploy the infrastructure

## Project Structure

```
frontend/   - Static web application (Vite + React)
backend/    - Lambda functions (Node.js ESM)
terraform/  - Infrastructure as Code (AWS)
```

## Local Development

### Frontend

```bash
cd frontend
npm install
npm run dev     # Start dev server
npm run build   # Production build
```

### Backend

Lambda functions are in `backend/`. Each subdirectory is a separate Lambda:

- `ws_auth/` - WebSocket JWT authorizer
- `ws_connect/` - WebSocket $connect handler
- `ws_disconnect/` - WebSocket $disconnect handler
- `ws_default/` - Message handling (send, edit, delete)
- `http_api/` - REST API handler

### Terraform

```bash
cd terraform
terraform init
terraform plan    # Review changes before applying
terraform apply
```

Required environment variables:

- `TF_VAR_base_domain`
- `TF_VAR_aws_region`
- `TF_VAR_state_bucket`
- `TF_VAR_lock_table`
- `TF_VAR_owner_email`
- `TF_VAR_owner_password`

## Branch Strategy

- `master` - Stable releases
- `dev` - Active development (target your PRs here)

## Pull Requests

- Keep PRs focused on a single change
- Ensure `npm run build` passes in `frontend/` before submitting
- Describe what your change does and why in the PR description
- Reference any related issues

## Reporting Issues

- Use GitHub Issues to report bugs or request features
- Include steps to reproduce for bug reports
- Include browser and environment details when relevant

## Code Style

- Frontend uses React with functional components and hooks
- Backend uses Node.js with ESM (`import`/`export`)
- Terraform follows the existing module structure

## License

By contributing to OpenCord, you agree that your contributions will be licensed under the [GNU General Public License v3.0](LICENSE).
