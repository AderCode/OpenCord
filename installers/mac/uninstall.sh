#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# OpenCord Uninstall Wizard — Mac / Linux
# ─────────────────────────────────────────────

# --- Colors & helpers ---

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header()  { printf "\n${BLUE}${BOLD}▶ %s${NC}\n" "$1"; }
print_success() { printf "${GREEN}✔ %s${NC}\n" "$1"; }
print_error()   { printf "${RED}✖ %s${NC}\n" "$1"; }
print_warn()    { printf "${YELLOW}⚠ %s${NC}\n" "$1"; }
print_info()    { printf "${CYAN}  %s${NC}\n" "$1"; }

prompt_input() {
  local prompt="$1" default="${2:-}"
  if [[ -n "$default" ]]; then
    printf "${BOLD}%s${NC} [%s]: " "$prompt" "$default"
  else
    printf "${BOLD}%s${NC}: " "$prompt"
  fi
  read -r value
  echo "${value:-$default}"
}

prompt_confirm() {
  local prompt="$1" default="${2:-Y}"
  if [[ "$default" == "Y" ]]; then
    printf "${BOLD}%s${NC} [Y/n]: " "$prompt"
  else
    printf "${BOLD}%s${NC} [y/N]: " "$prompt"
  fi
  read -r answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy] ]]
}

# --- Tracking ---
REPO_CLONED=false

# --- Repo resolution ---

REPO_URL="https://github.com/AderCode/OpenCord.git"

resolve_project_root() {
  local script_dir="$1"

  # 1. Inside the repo at installers/mac/ or installers/windows/
  local candidate
  candidate="$(cd "$script_dir/../.." 2>/dev/null && pwd)"
  if [[ -f "$candidate/terraform/main.tf" ]]; then
    PROJECT_ROOT="$candidate"
    print_success "Using repository at $PROJECT_ROOT"
    return
  fi

  # 2. Script copied to repo root
  if [[ -f "$script_dir/terraform/main.tf" ]]; then
    PROJECT_ROOT="$script_dir"
    print_success "Using repository at $PROJECT_ROOT"
    return
  fi

  # 3. Current working directory is the repo
  if [[ -f "terraform/main.tf" ]]; then
    PROJECT_ROOT="$(pwd)"
    print_success "Using repository at $PROJECT_ROOT"
    return
  fi

  # 4. OpenCord directory exists in current directory
  if [[ -f "OpenCord/terraform/main.tf" ]]; then
    PROJECT_ROOT="$(cd OpenCord && pwd)"
    print_success "Using repository at $PROJECT_ROOT"
    return
  fi

  # 5. Clone the repo (needed for terraform config files)
  print_info "OpenCord repository not found locally. Downloading (needed for Terraform config)..."
  if ! command -v git &>/dev/null; then
    print_error "git is required to download OpenCord. Please install git or clone the repo manually."
    exit 1
  fi
  git clone "$REPO_URL" OpenCord
  PROJECT_ROOT="$(cd OpenCord && pwd)"
  REPO_CLONED=true
  print_success "Repository downloaded to $PROJECT_ROOT"
}

# --- Main script ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "\n${BOLD}${RED}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║      OpenCord Uninstall Wizard        ║"
echo "  ╚═══════════════════════════════════════╝"
printf "${NC}\n"

print_warn "This will destroy all AWS resources created by OpenCord."
print_warn "This action cannot be undone. All data (messages, users, etc.) will be permanently deleted."
echo

if ! prompt_confirm "Are you sure you want to continue?"; then
  print_info "Aborted."
  exit 0
fi

# Step 1: Check prerequisites
print_header "Step 1/6: Checking prerequisites"

if ! command -v aws &>/dev/null; then
  print_error "AWS CLI is not installed. It is required to tear down resources."
  exit 1
fi
print_success "AWS CLI is installed"

if ! command -v terraform &>/dev/null; then
  print_error "Terraform is not installed. It is required to tear down resources."
  exit 1
fi
print_success "Terraform is installed"

print_info "Locating OpenCord project files..."
resolve_project_root "$SCRIPT_DIR"

# Step 2: Verify AWS credentials
print_header "Step 2/6: Verifying AWS credentials"

if aws sts get-caller-identity &>/dev/null; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  print_success "AWS credentials valid (Account: $ACCOUNT_ID)"
else
  print_error "AWS credentials are not configured. Run 'aws configure' first."
  exit 1
fi

# Step 3: Collect inputs
print_header "Step 3/6: Collecting configuration"

print_info "Enter the same values you used during installation."
echo

DOMAIN=""
while [[ -z "$DOMAIN" ]]; do
  DOMAIN=$(prompt_input "Domain name (e.g. mycommunity.chat)")
  if [[ -z "$DOMAIN" ]]; then
    print_error "Domain name is required."
  fi
done

STATE_BUCKET=""
while [[ -z "$STATE_BUCKET" ]]; do
  STATE_BUCKET=$(prompt_input "Terraform state S3 bucket name")
  if [[ -z "$STATE_BUCKET" ]]; then
    print_error "State bucket name is required."
  fi
done

LOCK_TABLE=$(prompt_input "Terraform lock DynamoDB table name" "opencord-tf-lock")
AWS_REGION="us-east-1"

echo
print_info "Configuration:"
print_info "  Domain:       $DOMAIN"
print_info "  State bucket: $STATE_BUCKET"
print_info "  Lock table:   $LOCK_TABLE"
print_info "  Region:       $AWS_REGION"
echo

printf "${RED}${BOLD}This will permanently destroy all OpenCord infrastructure for ${DOMAIN}.${NC}\n"
if ! prompt_confirm "Type Y to confirm destruction"; then
  print_info "Aborted."
  exit 0
fi

# Step 4: Terraform destroy
print_header "Step 4/6: Destroying infrastructure with Terraform"

cd "$PROJECT_ROOT/terraform"

print_info "Running terraform init..."
terraform init \
  -backend-config="bucket=$STATE_BUCKET" \
  -backend-config="key=opencord/terraform.tfstate" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="dynamodb_table=$LOCK_TABLE" \
  -backend-config="encrypt=true"

print_info "Running terraform destroy (this may take several minutes)..."
terraform destroy -auto-approve \
  -var="base_domain=$DOMAIN" \
  -var="aws_region=$AWS_REGION" \
  -var="state_bucket=$STATE_BUCKET" \
  -var="lock_table=$LOCK_TABLE" \
  -var="owner_email=placeholder@example.com" \
  -var="owner_password=Placeholder1"

print_success "All AWS infrastructure destroyed"

# Step 5: Clean up state storage
print_header "Step 5/6: Cleaning up Terraform state storage"

print_info "The S3 bucket and DynamoDB table used for Terraform state are not"
print_info "managed by Terraform itself. They can be deleted separately."
echo

if prompt_confirm "Delete the Terraform state S3 bucket ($STATE_BUCKET)?" "N"; then
  print_info "Emptying bucket before deletion..."
  aws s3 rm "s3://$STATE_BUCKET" --recursive
  # Also remove any versioned delete markers
  VERSIONS=$(aws s3api list-object-versions --bucket "$STATE_BUCKET" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null || echo '{"Objects":null}')
  if [[ "$VERSIONS" != '{"Objects":null}' && "$VERSIONS" != *'"Objects": null'* ]]; then
    echo "$VERSIONS" | aws s3api delete-objects --bucket "$STATE_BUCKET" --delete file:///dev/stdin >/dev/null 2>&1 || true
  fi
  DELETE_MARKERS=$(aws s3api list-object-versions --bucket "$STATE_BUCKET" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null || echo '{"Objects":null}')
  if [[ "$DELETE_MARKERS" != '{"Objects":null}' && "$DELETE_MARKERS" != *'"Objects": null'* ]]; then
    echo "$DELETE_MARKERS" | aws s3api delete-objects --bucket "$STATE_BUCKET" --delete file:///dev/stdin >/dev/null 2>&1 || true
  fi
  aws s3api delete-bucket --bucket "$STATE_BUCKET" --region "$AWS_REGION"
  print_success "S3 bucket deleted"
else
  print_info "Skipped — bucket '$STATE_BUCKET' was kept."
fi

if prompt_confirm "Delete the Terraform lock DynamoDB table ($LOCK_TABLE)?" "N"; then
  aws dynamodb delete-table --table-name "$LOCK_TABLE" --region "$AWS_REGION" >/dev/null
  print_success "DynamoDB table deleted"
else
  print_info "Skipped — table '$LOCK_TABLE' was kept."
fi

# Step 6: Clean up local files
print_header "Step 6/6: Cleaning up local files"

if prompt_confirm "Remove local build artifacts and config? (frontend/.env, frontend/dist/, frontend/node_modules/, terraform/.terraform/)" "N"; then
  rm -f  "$PROJECT_ROOT/frontend/.env"
  rm -rf "$PROJECT_ROOT/frontend/dist"
  rm -rf "$PROJECT_ROOT/frontend/node_modules"
  rm -rf "$PROJECT_ROOT/terraform/.terraform"
  rm -f  "$PROJECT_ROOT/terraform/.terraform.lock.hcl"
  print_success "Local files cleaned up"
else
  print_info "Skipped — local files were kept."
fi

# Done
printf "\n${GREEN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║         OpenCord has been removed.                ║"
echo "  ╚═══════════════════════════════════════════════════╝"
printf "${NC}\n"

print_info "All AWS resources for $DOMAIN have been destroyed."
print_info "If you kept the state bucket or lock table, you can delete them"
print_info "manually later from the AWS console."
echo
print_success "Done. Thanks for using OpenCord!"

# --- Cleanup ---
if [[ "$REPO_CLONED" == "true" ]]; then
  echo
  print_header "Cleanup"
  if prompt_confirm "Remove the downloaded OpenCord repository ($PROJECT_ROOT)?" "N"; then
    rm -rf "$PROJECT_ROOT"
    print_success "Downloaded repository removed"
  else
    print_info "Kept repository at $PROJECT_ROOT"
  fi
fi
