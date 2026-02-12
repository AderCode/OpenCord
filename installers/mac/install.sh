#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# OpenCord Install Wizard — Mac / Linux
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

prompt_secret() {
  local prompt="$1"
  printf "${BOLD}%s${NC}: " "$prompt"
  read -rs value
  echo
  echo "$value"
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
# Records what the wizard installs so we can offer cleanup at the end.
# Each entry: "display_name:brew_pkg:apt_pkg:dnf_pkg"
INSTALLED_TOOLS=()
REPO_CLONED=false

# --- Repo resolution ---

REPO_URL="https://github.com/AderCode/OpenCord.git"

resolve_project_root() {
  local script_dir="$1"

  # 1. Inside the repo at installers/mac/ or installers/windows/
  local candidate
  candidate="$(cd "$script_dir/../.." 2>/dev/null && pwd)"
  if [[ -f "$candidate/terraform/main.tf" && -f "$candidate/frontend/package.json" ]]; then
    PROJECT_ROOT="$candidate"
    print_success "Using repository at $PROJECT_ROOT"
    return
  fi

  # 2. Script copied to repo root
  if [[ -f "$script_dir/terraform/main.tf" && -f "$script_dir/frontend/package.json" ]]; then
    PROJECT_ROOT="$script_dir"
    print_success "Using repository at $PROJECT_ROOT"
    return
  fi

  # 3. Current working directory is the repo
  if [[ -f "terraform/main.tf" && -f "frontend/package.json" ]]; then
    PROJECT_ROOT="$(pwd)"
    print_success "Using repository at $PROJECT_ROOT"
    return
  fi

  # 4. OpenCord directory exists in current directory
  if [[ -f "OpenCord/terraform/main.tf" && -f "OpenCord/frontend/package.json" ]]; then
    PROJECT_ROOT="$(cd OpenCord && pwd)"
    print_success "Using repository at $PROJECT_ROOT"
    return
  fi

  # 5. Clone the repo
  print_info "OpenCord repository not found locally. Downloading..."
  if ! command -v git &>/dev/null; then
    print_error "git is required to download OpenCord. Please install git or clone the repo manually."
    exit 1
  fi
  git clone "$REPO_URL" OpenCord
  PROJECT_ROOT="$(cd OpenCord && pwd)"
  REPO_CLONED=true
  print_success "Repository downloaded to $PROJECT_ROOT"
}

# --- Step 1: Prerequisites ---

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "mac"
  elif command -v apt-get &>/dev/null; then
    echo "linux-apt"
  elif command -v dnf &>/dev/null; then
    echo "linux-dnf"
  else
    echo "unknown"
  fi
}

check_and_install() {
  local cmd="$1" display_name="$2" brew_pkg="$3" apt_pkg="$4" dnf_pkg="$5"
  if command -v "$cmd" &>/dev/null; then
    print_success "$display_name is installed"
    return 0
  fi

  print_warn "$display_name is not installed."
  if ! prompt_confirm "Install $display_name now?"; then
    print_error "Cannot continue without $display_name. Please install it manually and re-run."
    exit 1
  fi

  local os
  os=$(detect_os)
  case "$os" in
    mac)
      if ! command -v brew &>/dev/null; then
        print_error "Homebrew is required to install packages on Mac."
        print_info "Install it from https://brew.sh and re-run."
        exit 1
      fi
      brew install $brew_pkg
      ;;
    linux-apt)
      sudo apt-get update -qq && sudo apt-get install -y $apt_pkg
      ;;
    linux-dnf)
      sudo dnf install -y $dnf_pkg
      ;;
    *)
      print_error "Could not detect a supported package manager. Please install $display_name manually."
      exit 1
      ;;
  esac

  if command -v "$cmd" &>/dev/null; then
    print_success "$display_name installed successfully"
    INSTALLED_TOOLS+=("$display_name:$brew_pkg:$apt_pkg:$dnf_pkg")
  else
    print_error "Failed to install $display_name. Please install it manually and re-run."
    exit 1
  fi
}

install_terraform_linux_apt() {
  if command -v terraform &>/dev/null; then
    print_success "Terraform is installed"
    return 0
  fi

  print_warn "Terraform is not installed."
  if ! prompt_confirm "Install Terraform now?"; then
    print_error "Cannot continue without Terraform. Please install it manually and re-run."
    exit 1
  fi

  sudo apt-get update -qq && sudo apt-get install -y gnupg software-properties-common
  wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update -qq && sudo apt-get install -y terraform

  if command -v terraform &>/dev/null; then
    print_success "Terraform installed successfully"
    INSTALLED_TOOLS+=("Terraform::terraform:")
  else
    print_error "Failed to install Terraform. Please install it manually and re-run."
    exit 1
  fi
}

install_terraform_linux_dnf() {
  if command -v terraform &>/dev/null; then
    print_success "Terraform is installed"
    return 0
  fi

  print_warn "Terraform is not installed."
  if ! prompt_confirm "Install Terraform now?"; then
    print_error "Cannot continue without Terraform. Please install it manually and re-run."
    exit 1
  fi

  sudo dnf install -y dnf-plugins-core
  sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
  sudo dnf install -y terraform

  if command -v terraform &>/dev/null; then
    print_success "Terraform installed successfully"
    INSTALLED_TOOLS+=("Terraform:::terraform")
  else
    print_error "Failed to install Terraform. Please install it manually and re-run."
    exit 1
  fi
}

# --- Main script ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "\n${BOLD}${CYAN}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║       OpenCord Install Wizard         ║"
echo "  ╚═══════════════════════════════════════╝"
printf "${NC}\n"

# Step 1: Prerequisites
print_header "Step 1/8: Checking prerequisites"

OS_TYPE=$(detect_os)
print_info "Detected platform: $OS_TYPE"

check_and_install "aws" "AWS CLI" "awscli" "awscli" "awscli2"

case "$OS_TYPE" in
  mac)       check_and_install "terraform" "Terraform" "hashicorp/tap/terraform" "" "" ;;
  linux-apt) install_terraform_linux_apt ;;
  linux-dnf) install_terraform_linux_dnf ;;
  *)         check_and_install "terraform" "Terraform" "" "" "" ;;
esac

check_and_install "node" "Node.js" "node" "nodejs" "nodejs"
check_and_install "npm"  "npm"     "node" "npm"    "npm"
check_and_install "git"  "Git"     "git"  "git"    "git"

print_info "Locating OpenCord project files..."
resolve_project_root "$SCRIPT_DIR"

# Step 2: AWS credentials
print_header "Step 2/8: Verifying AWS credentials"

if aws sts get-caller-identity &>/dev/null; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  print_success "AWS credentials valid (Account: $ACCOUNT_ID)"
else
  print_warn "AWS credentials are not configured."
  print_info "Running 'aws configure' — follow the prompts to enter your credentials."
  aws configure
  if aws sts get-caller-identity &>/dev/null; then
    print_success "AWS credentials configured successfully"
  else
    print_error "AWS credentials are still invalid. Please check your access keys and re-run."
    exit 1
  fi
fi

# Step 3: Collect user inputs
print_header "Step 3/8: Collecting configuration"

DOMAIN=""
while [[ -z "$DOMAIN" ]]; do
  DOMAIN=$(prompt_input "Domain name (e.g. mycommunity.chat)")
  if [[ -z "$DOMAIN" ]]; then
    print_error "Domain name is required."
  fi
done

OWNER_EMAIL=""
while [[ -z "$OWNER_EMAIL" ]]; do
  OWNER_EMAIL=$(prompt_input "Owner email address")
  if [[ -z "$OWNER_EMAIL" ]]; then
    print_error "Owner email is required."
  elif [[ ! "$OWNER_EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
    print_error "Please enter a valid email address."
    OWNER_EMAIL=""
  fi
done

OWNER_PASSWORD=""
while [[ -z "$OWNER_PASSWORD" ]]; do
  OWNER_PASSWORD=$(prompt_secret "Owner password (min 8 chars, uppercase, lowercase, number)")
  if [[ ${#OWNER_PASSWORD} -lt 8 ]]; then
    print_error "Password must be at least 8 characters."
    OWNER_PASSWORD=""
  elif [[ ! "$OWNER_PASSWORD" =~ [A-Z] ]]; then
    print_error "Password must contain at least one uppercase letter."
    OWNER_PASSWORD=""
  elif [[ ! "$OWNER_PASSWORD" =~ [a-z] ]]; then
    print_error "Password must contain at least one lowercase letter."
    OWNER_PASSWORD=""
  elif [[ ! "$OWNER_PASSWORD" =~ [0-9] ]]; then
    print_error "Password must contain at least one number."
    OWNER_PASSWORD=""
  fi
done

RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 8 || true)
DEFAULT_BUCKET="opencord-tf-state-${RANDOM_SUFFIX}"
STATE_BUCKET=$(prompt_input "Terraform state S3 bucket name" "$DEFAULT_BUCKET")
LOCK_TABLE=$(prompt_input "Terraform lock DynamoDB table name" "opencord-tf-lock")

ENABLE_KMS=false
if prompt_confirm "Enable KMS encryption? (adds ~\$2/month)" "N"; then
  ENABLE_KMS=true
fi

AWS_REGION="us-east-1"

echo
print_info "Configuration summary:"
print_info "  Domain:       $DOMAIN"
print_info "  Owner email:  $OWNER_EMAIL"
print_info "  State bucket: $STATE_BUCKET"
print_info "  Lock table:   $LOCK_TABLE"
print_info "  KMS:          $ENABLE_KMS"
print_info "  Region:       $AWS_REGION"
echo

if ! prompt_confirm "Proceed with deployment?"; then
  print_warn "Aborted."
  exit 0
fi

# Step 4: Bootstrap Terraform state
print_header "Step 4/8: Creating Terraform state storage"

if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
  print_info "S3 bucket '$STATE_BUCKET' already exists — skipping creation."
else
  print_info "Creating S3 bucket: $STATE_BUCKET"
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "$STATE_BUCKET" \
      --region "$AWS_REGION"
  else
    aws s3api create-bucket \
      --bucket "$STATE_BUCKET" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi
  aws s3api put-bucket-versioning \
    --bucket "$STATE_BUCKET" \
    --versioning-configuration Status=Enabled
  print_success "S3 bucket created"
fi

if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$AWS_REGION" &>/dev/null; then
  print_info "DynamoDB table '$LOCK_TABLE' already exists — skipping creation."
else
  print_info "Creating DynamoDB table: $LOCK_TABLE"
  aws dynamodb create-table \
    --table-name "$LOCK_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION"
  print_info "Waiting for table to become active..."
  aws dynamodb wait table-exists --table-name "$LOCK_TABLE" --region "$AWS_REGION"
  print_success "DynamoDB table created"
fi

# Step 5: Terraform init & apply
print_header "Step 5/8: Deploying infrastructure with Terraform"

cd "$PROJECT_ROOT/terraform"

print_info "Running terraform init..."
terraform init \
  -backend-config="bucket=$STATE_BUCKET" \
  -backend-config="key=opencord/terraform.tfstate" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="dynamodb_table=$LOCK_TABLE" \
  -backend-config="encrypt=true"

print_info "Running terraform apply (this may take 10-30 minutes)..."
terraform apply -auto-approve \
  -var="base_domain=$DOMAIN" \
  -var="aws_region=$AWS_REGION" \
  -var="state_bucket=$STATE_BUCKET" \
  -var="lock_table=$LOCK_TABLE" \
  -var="owner_email=$OWNER_EMAIL" \
  -var="owner_password=$OWNER_PASSWORD" \
  -var="enable_kms_encryption=$ENABLE_KMS"

COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket)
print_success "Infrastructure deployed"

# Step 6: Build frontend
print_header "Step 6/8: Building frontend"

cd "$PROJECT_ROOT/frontend"

print_info "Writing .env file..."
cat > .env <<EOF
VITE_BASE_DOMAIN=$DOMAIN
VITE_COGNITO_CLIENT_ID=$COGNITO_CLIENT_ID
EOF

print_info "Installing npm dependencies..."
npm install

print_info "Building frontend..."
npm run build

print_success "Frontend built"

# Step 7: Upload to S3
print_header "Step 7/8: Uploading frontend to S3"

print_info "Syncing dist/ to s3://$FRONTEND_BUCKET ..."
aws s3 sync dist/ "s3://$FRONTEND_BUCKET" --delete

print_success "Frontend uploaded"

# Step 8: Done
print_header "Step 8/8: Setup complete!"

printf "\n${GREEN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║            OpenCord is live!                      ║"
echo "  ╚═══════════════════════════════════════════════════╝"
printf "${NC}\n"

print_info "URL:         https://cdn.$DOMAIN"
print_info "Owner email: $OWNER_EMAIL"
print_info "Owner password: (the one you entered during setup)"
echo
print_warn "If your domain was recently pointed to Route 53, DNS may"
print_warn "take a few minutes to propagate. If the site doesn't load"
print_warn "immediately, wait a bit and try again."
echo
print_success "Done! Open https://cdn.$DOMAIN in your browser to get started."

# --- Cleanup ---
# Offer to remove things this script installed/downloaded.

if [[ "$REPO_CLONED" == "true" || ${#INSTALLED_TOOLS[@]} -gt 0 ]]; then
  echo
  print_header "Cleanup"
  print_info "The wizard installed some things on your system during this run."
  echo
fi

if [[ "$REPO_CLONED" == "true" ]]; then
  if prompt_confirm "Remove the downloaded OpenCord repository ($PROJECT_ROOT)?" "N"; then
    rm -rf "$PROJECT_ROOT"
    print_success "Downloaded repository removed"
  else
    print_info "Kept repository at $PROJECT_ROOT"
  fi
fi

if [[ ${#INSTALLED_TOOLS[@]} -gt 0 ]]; then
  print_info "The following tools were installed by this wizard:"
  for tool_info in "${INSTALLED_TOOLS[@]}"; do
    IFS=':' read -r name _ _ _ <<< "$tool_info"
    print_info "  - $name"
  done
  echo
  if prompt_confirm "Uninstall these tools?" "N"; then
    for tool_info in "${INSTALLED_TOOLS[@]}"; do
      IFS=':' read -r name brew_pkg apt_pkg dnf_pkg <<< "$tool_info"
      print_info "Removing $name..."
      case "$OS_TYPE" in
        mac)
          if [[ -n "$brew_pkg" ]]; then
            brew uninstall "$brew_pkg" 2>/dev/null || true
          fi
          ;;
        linux-apt)
          if [[ -n "$apt_pkg" ]]; then
            sudo apt-get remove -y $apt_pkg 2>/dev/null || true
          fi
          ;;
        linux-dnf)
          if [[ -n "$dnf_pkg" ]]; then
            sudo dnf remove -y $dnf_pkg 2>/dev/null || true
          fi
          ;;
      esac
    done
    print_success "Tools uninstalled"
  else
    print_info "Kept all installed tools."
  fi
fi
