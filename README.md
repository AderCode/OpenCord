# OpenCord

An open-source, self-hosted community platform for real-time chat — built on AWS serverless infrastructure so you own your data and pay only for what you use.

## What is OpenCord?

OpenCord gives you a Discord-like experience that you run yourself. Set it up on your own domain, invite your community, and chat in real time — all without relying on a third-party service. Because it runs entirely on AWS serverless technology, there are no servers to manage and costs stay near zero for small communities.

### Features

- **Real-time messaging** with WebSocket-powered chat
- **Channels** to organize conversations by topic
- **Message editing and deletion** for all users
- **Owner moderation** — a designated Owner account can edit or delete any message
- **Installable PWA** — works as a native-feeling app on desktop and mobile
- **Serverless architecture** — no servers to maintain, scales automatically, pay-per-use pricing
- **Single-domain setup** — one domain powers everything (`api.`, `ws.`, `auth.`, `cdn.`)

## What You'll Need

Before you begin, make sure you have the following:

1. **An AWS account** — [Create one here](https://aws.amazon.com/free/) if you don't have one. The free tier covers most of what OpenCord uses.
2. **A domain name** — You'll need a domain you own (e.g. `mycommunity.chat`). You can buy one through [AWS Route 53 (easiest)](https://aws.amazon.com/route53/), [Namecheap](https://www.namecheap.com/), [Cloudflare](https://www.cloudflare.com/products/registrar/), or any registrar.
3. **A computer with a terminal** — Mac, Linux, or Windows (with WSL) all work.

### Software to Install

| Tool                  | What it does                           | Install guide                                                                                          |
| --------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **Node.js** (v18+)    | Builds the frontend                    | [nodejs.org](https://nodejs.org/)                                                                      |
| **Terraform** (v1.0+) | Deploys your infrastructure to AWS     | [terraform.io/downloads](https://developer.hashicorp.com/terraform/downloads)                          |
| **AWS CLI** (v2)      | Connects Terraform to your AWS account | [AWS CLI install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **Git**               | Downloads the OpenCord code            | [git-scm.com](https://git-scm.com/downloads)                                                           |

### Quick Start (Recommended)

Once you have your AWS credentials configured (Step 1) and domain pointed to Route 53 (Step 2), the install wizard handles everything else. The scripts work standalone — if the repository isn't already cloned, they'll download it automatically.

**Mac / Linux:**
```bash
./installers/mac/install.sh
```

**Windows (PowerShell):**
```powershell
.\installers\windows\install.ps1
```

The wizard will check for missing tools, offer to install them, and walk you through the rest. Continue below if you prefer manual setup.

## Setup Guide

### Step 1: Configure AWS credentials

After installing the AWS CLI, connect it to your AWS account. Run this in your terminal and follow the prompts:

```bash
aws configure
```

You'll need your **Access Key ID** and **Secret Access Key** from the AWS console. If you don't have these yet:

1. Go to the [AWS IAM console](https://console.aws.amazon.com/iam/)
2. Click **Users** > **Create user**
3. Give the user **AdministratorAccess** (you can tighten permissions later)
4. Create an access key and copy the two values into `aws configure`

Set your region to `us-east-1` when prompted — OpenCord requires this region for SSL certificates.

### Step 2: Point your domain to AWS

If your domain is **not** registered through AWS Route 53, you'll need to point it there:

1. Go to the [Route 53 console](https://console.aws.amazon.com/route53/)
2. Click **Hosted zones** > **Create hosted zone**
3. Enter your domain name and click **Create**
4. Route 53 will give you 4 **nameserver (NS)** records
5. Go to your domain registrar and replace the existing nameservers with these 4 values

If your domain is already in Route 53, you can skip this — Terraform will handle the rest.

> **Note:** Nameserver changes can take up to 48 hours to propagate, but usually complete within a few minutes to a couple of hours.

### Step 3: Create the Terraform state storage

Terraform needs a place to store its state file so it can track what it has deployed. Run these two commands, replacing the names if you'd like:

```bash
aws s3api create-bucket \
  --bucket my-opencord-tf-state \
  --region us-east-1

aws dynamodb create-table \
  --table-name opencord-tf-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Remember the bucket name (`my-opencord-tf-state`) and table name (`opencord-tf-lock`) — you'll need them in the next step.

### Step 4: Download OpenCord

```bash
git clone https://github.com/yourusername/OpenCord.git
cd OpenCord
```

### Step 5: Deploy the infrastructure

Navigate to the Terraform directory and initialize it with your state storage details:

```bash
cd terraform

terraform init \
  -backend-config="bucket=my-opencord-tf-state" \
  -backend-config="key=opencord/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=opencord-tf-lock" \
  -backend-config="encrypt=true"
```

Now set your configuration and deploy. Replace the placeholder values with your own:

```bash
export TF_VAR_base_domain="mycommunity.chat"
export TF_VAR_aws_region="us-east-1"
export TF_VAR_state_bucket="my-opencord-tf-state"
export TF_VAR_lock_table="opencord-tf-lock"
export TF_VAR_owner_email="you@example.com"
export TF_VAR_owner_password="YourSecurePassword1"
```

| Variable                | What to put                                                                              |
| ----------------------- | ---------------------------------------------------------------------------------------- |
| `TF_VAR_base_domain`    | Your domain name (e.g. `mycommunity.chat`)                                               |
| `TF_VAR_aws_region`     | Keep this as `us-east-1`                                                                 |
| `TF_VAR_state_bucket`   | The S3 bucket name from Step 3                                                           |
| `TF_VAR_lock_table`     | The DynamoDB table name from Step 3                                                      |
| `TF_VAR_owner_email`    | The email address for your Owner (admin) account                                         |
| `TF_VAR_owner_password` | A password for the Owner account (min 8 chars, needs uppercase, lowercase, and a number) |

Then deploy:

```bash
terraform apply
```

Terraform will show you a plan of everything it's about to create. Type `yes` to confirm. This will take a few minutes.

> **Note:** SSL certificate validation and CloudFront distribution can take 10-30 minutes on first deploy. This is normal.

### Step 6: Build and upload the frontend

After Terraform finishes, it will output a **Cognito Client ID**. You'll need this to build the frontend.

Go back to the project root and set up the frontend:

```bash
cd ../frontend
cp .env.example .env
```

Edit the `.env` file with your values:

```
VITE_BASE_DOMAIN=mycommunity.chat
VITE_COGNITO_CLIENT_ID=your-cognito-client-id-from-terraform-output
```

Build and upload:

```bash
npm install
npm run build
aws s3 sync dist/ s3://cdn.mycommunity.chat --delete
```

Replace `mycommunity.chat` with your actual domain.

### Step 7: Visit your community

Open your browser and go to:

```
https://cdn.mycommunity.chat
```

Sign up for an account, or log in with the Owner email and password you set in Step 5. The Owner account has full moderation powers — it can edit and delete any message.

## Architecture Overview

OpenCord is fully serverless on AWS. Your domain powers four endpoints:

| URL                           | Purpose                       |
| ----------------------------- | ----------------------------- |
| `https://api.yourdomain.com`  | REST API for message history  |
| `wss://ws.yourdomain.com`     | WebSocket for real-time chat  |
| `https://auth.yourdomain.com` | User authentication (Cognito) |
| `https://cdn.yourdomain.com`  | The web app itself            |

**AWS services used:**

- **Route 53** — DNS
- **ACM** — SSL certificates
- **Cognito** — User accounts and authentication
- **API Gateway** — HTTP and WebSocket APIs
- **Lambda** — Backend logic (runs only when needed)
- **DynamoDB** — Message and connection storage
- **S3 + CloudFront** — Frontend hosting and CDN
- **CloudWatch** — Logging and monitoring

## Cost

For a small community (under a few hundred users), your AWS bill will typically be **under $1/month** thanks to serverless pay-per-use pricing and the AWS free tier. The main ongoing costs are Route 53 hosting ($0.50/month per hosted zone) and minimal Lambda/DynamoDB usage.

## Tearing Down

The uninstall wizard handles everything — it destroys all AWS infrastructure, and optionally removes the Terraform state storage and local build files:

**Mac / Linux:**
```bash
./installers/mac/uninstall.sh
```

**Windows (PowerShell):**
```powershell
.\installers\windows\uninstall.ps1
```

Or, if you prefer to do it manually:

```bash
cd terraform
terraform destroy
```

Type `yes` to confirm. This removes all AWS resources. You'll also want to delete the state bucket and lock table you created in Step 3 if you no longer need them.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute.

## License

OpenCord is licensed under the [GNU General Public License v3.0](LICENSE).
