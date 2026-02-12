#Requires -Version 5.1
<#
.SYNOPSIS
    OpenCord Install Wizard — Windows (PowerShell)
.DESCRIPTION
    Interactive wizard that checks prerequisites, collects configuration,
    deploys infrastructure via Terraform, builds the frontend, and uploads
    it to S3.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────
# Colors & helpers
# ─────────────────────────────────────────────

function Print-Header  { param([string]$Msg) Write-Host "`n>> $Msg" -ForegroundColor Blue }
function Print-Success { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Print-Error   { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }
function Print-Warn    { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Print-Info    { param([string]$Msg) Write-Host "  $Msg" -ForegroundColor Cyan }

function Prompt-Input {
    param([string]$Prompt, [string]$Default = "")
    if ($Default) {
        $value = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
        return $value
    }
    return Read-Host $Prompt
}

function Prompt-Secret {
    param([string]$Prompt)
    $secure = Read-Host $Prompt -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Prompt-Confirm {
    param([string]$Prompt, [string]$Default = "Y")
    if ($Default -eq "Y") {
        $answer = Read-Host "$Prompt [Y/n]"
    } else {
        $answer = Read-Host "$Prompt [y/N]"
    }
    if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $Default }
    return $answer -match '^[Yy]'
}

function Assert-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-WithWinget {
    param([string]$DisplayName, [string]$WingetId)
    if (-not (Assert-Command "winget")) {
        Print-Error "winget is required to install packages. Please install $DisplayName manually."
        exit 1
    }
    Print-Info "Installing $DisplayName via winget..."
    winget install --id $WingetId --accept-source-agreements --accept-package-agreements
}

function Check-AndInstall {
    param(
        [string]$Command,
        [string]$DisplayName,
        [string]$WingetId
    )
    if (Assert-Command $Command) {
        Print-Success "$DisplayName is installed"
        return
    }

    Print-Warn "$DisplayName is not installed."
    if (-not (Prompt-Confirm "Install $DisplayName now?")) {
        Print-Error "Cannot continue without $DisplayName. Please install it manually and re-run."
        exit 1
    }

    Install-WithWinget $DisplayName $WingetId

    # Refresh PATH so the newly installed command is found
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + `
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Assert-Command $Command) {
        Print-Success "$DisplayName installed successfully"
        $script:InstalledTools += @{ Name = $DisplayName; WingetId = $WingetId }
    } else {
        Print-Error "Failed to install $DisplayName. You may need to restart your terminal, then re-run this script."
        exit 1
    }
}

# ─────────────────────────────────────────────
# Tracking — records what we install so we can offer cleanup
# ─────────────────────────────────────────────

$script:InstalledTools = @()   # list of @{Name; WingetId} hashtables
$script:RepoCloned = $false

# ─────────────────────────────────────────────
# Repo resolution
# ─────────────────────────────────────────────

$RepoUrl = "https://github.com/AderCode/OpenCord.git"

function Resolve-ProjectRoot {
    param([string]$ScriptDir)

    # 1. Inside the repo at installers\windows\
    $candidate = (Resolve-Path "$ScriptDir\..\.." -ErrorAction SilentlyContinue).Path
    if ($candidate -and (Test-Path "$candidate\terraform\main.tf") -and (Test-Path "$candidate\frontend\package.json")) {
        Print-Success "Using repository at $candidate"
        return $candidate
    }

    # 2. Script copied to repo root
    if ((Test-Path "$ScriptDir\terraform\main.tf") -and (Test-Path "$ScriptDir\frontend\package.json")) {
        Print-Success "Using repository at $ScriptDir"
        return $ScriptDir
    }

    # 3. Current working directory is the repo
    $cwd = (Get-Location).Path
    if ((Test-Path "$cwd\terraform\main.tf") -and (Test-Path "$cwd\frontend\package.json")) {
        Print-Success "Using repository at $cwd"
        return $cwd
    }

    # 4. OpenCord directory exists in current directory
    if ((Test-Path "$cwd\OpenCord\terraform\main.tf") -and (Test-Path "$cwd\OpenCord\frontend\package.json")) {
        $path = (Resolve-Path "$cwd\OpenCord").Path
        Print-Success "Using repository at $path"
        return $path
    }

    # 5. Clone the repo
    Print-Info "OpenCord repository not found locally. Downloading..."
    if (-not (Assert-Command "git")) {
        Print-Error "git is required to download OpenCord. Please install git or clone the repo manually."
        exit 1
    }
    git clone $RepoUrl OpenCord
    $path = (Resolve-Path "$cwd\OpenCord").Path
    $script:RepoCloned = $true
    Print-Success "Repository downloaded to $path"
    return $path
}

# ─────────────────────────────────────────────
# Main script
# ─────────────────────────────────────────────

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host ""
Write-Host "  +=======================================+" -ForegroundColor Cyan
Write-Host "  |       OpenCord Install Wizard         |" -ForegroundColor Cyan
Write-Host "  +=======================================+" -ForegroundColor Cyan
Write-Host ""

# Step 1: Prerequisites
Print-Header "Step 1/8: Checking prerequisites"

Check-AndInstall "aws"       "AWS CLI"   "Amazon.AWSCLI"
Check-AndInstall "terraform" "Terraform" "Hashicorp.Terraform"
Check-AndInstall "node"      "Node.js"   "OpenJS.NodeJS.LTS"
Check-AndInstall "npm"       "npm"       "OpenJS.NodeJS.LTS"
Check-AndInstall "git"       "Git"       "Git.Git"

Print-Info "Locating OpenCord project files..."
$ProjectRoot = Resolve-ProjectRoot $ScriptDir

# Step 2: AWS credentials
Print-Header "Step 2/8: Verifying AWS credentials"

try {
    $identity = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
    Print-Success "AWS credentials valid (Account: $($identity.Account))"
} catch {
    Print-Warn "AWS credentials are not configured."
    Print-Info "Running 'aws configure' - follow the prompts to enter your credentials."
    aws configure
    try {
        $null = aws sts get-caller-identity 2>$null
        Print-Success "AWS credentials configured successfully"
    } catch {
        Print-Error "AWS credentials are still invalid. Please check your access keys and re-run."
        exit 1
    }
}

# Step 3: Collect user inputs
Print-Header "Step 3/8: Collecting configuration"

$Domain = ""
while ([string]::IsNullOrWhiteSpace($Domain)) {
    $Domain = Prompt-Input "Domain name (e.g. mycommunity.chat)"
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        Print-Error "Domain name is required."
    }
}

$OwnerEmail = ""
while ([string]::IsNullOrWhiteSpace($OwnerEmail)) {
    $OwnerEmail = Prompt-Input "Owner email address"
    if ([string]::IsNullOrWhiteSpace($OwnerEmail)) {
        Print-Error "Owner email is required."
    } elseif ($OwnerEmail -notmatch '^[^@]+@[^@]+\.[^@]+$') {
        Print-Error "Please enter a valid email address."
        $OwnerEmail = ""
    }
}

$OwnerPassword = ""
while ([string]::IsNullOrWhiteSpace($OwnerPassword)) {
    $OwnerPassword = Prompt-Secret "Owner password (min 8 chars, uppercase, lowercase, number)"
    if ($OwnerPassword.Length -lt 8) {
        Print-Error "Password must be at least 8 characters."
        $OwnerPassword = ""
    } elseif ($OwnerPassword -cnotmatch '[A-Z]') {
        Print-Error "Password must contain at least one uppercase letter."
        $OwnerPassword = ""
    } elseif ($OwnerPassword -cnotmatch '[a-z]') {
        Print-Error "Password must contain at least one lowercase letter."
        $OwnerPassword = ""
    } elseif ($OwnerPassword -notmatch '[0-9]') {
        Print-Error "Password must contain at least one number."
        $OwnerPassword = ""
    }
}

$RandomSuffix = -join ((97..122) + (48..57) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
$DefaultBucket = "opencord-tf-state-$RandomSuffix"
$StateBucket = Prompt-Input "Terraform state S3 bucket name" $DefaultBucket
$LockTable   = Prompt-Input "Terraform lock DynamoDB table name" "opencord-tf-lock"

$EnableKms = $false
if (Prompt-Confirm "Enable KMS encryption? (adds ~`$2/month)" "N") {
    $EnableKms = $true
}

$AwsRegion = "us-east-1"

Write-Host ""
Print-Info "Configuration summary:"
Print-Info "  Domain:       $Domain"
Print-Info "  Owner email:  $OwnerEmail"
Print-Info "  State bucket: $StateBucket"
Print-Info "  Lock table:   $LockTable"
Print-Info "  KMS:          $EnableKms"
Print-Info "  Region:       $AwsRegion"
Write-Host ""

if (-not (Prompt-Confirm "Proceed with deployment?")) {
    Print-Warn "Aborted."
    exit 0
}

# Step 4: Bootstrap Terraform state
Print-Header "Step 4/8: Creating Terraform state storage"

$bucketExists = $false
try {
    aws s3api head-bucket --bucket $StateBucket 2>$null
    $bucketExists = $true
} catch { }

if ($bucketExists) {
    Print-Info "S3 bucket '$StateBucket' already exists - skipping creation."
} else {
    Print-Info "Creating S3 bucket: $StateBucket"
    aws s3api create-bucket `
        --bucket $StateBucket `
        --region $AwsRegion
    aws s3api put-bucket-versioning `
        --bucket $StateBucket `
        --versioning-configuration Status=Enabled
    Print-Success "S3 bucket created"
}

$tableExists = $false
try {
    aws dynamodb describe-table --table-name $LockTable --region $AwsRegion 2>$null | Out-Null
    $tableExists = $true
} catch { }

if ($tableExists) {
    Print-Info "DynamoDB table '$LockTable' already exists - skipping creation."
} else {
    Print-Info "Creating DynamoDB table: $LockTable"
    aws dynamodb create-table `
        --table-name $LockTable `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $AwsRegion
    Print-Info "Waiting for table to become active..."
    aws dynamodb wait table-exists --table-name $LockTable --region $AwsRegion
    Print-Success "DynamoDB table created"
}

# Step 5: Terraform init & apply
Print-Header "Step 5/8: Deploying infrastructure with Terraform"

Set-Location "$ProjectRoot\terraform"

Print-Info "Running terraform init..."
terraform init `
    -backend-config="bucket=$StateBucket" `
    -backend-config="key=opencord/terraform.tfstate" `
    -backend-config="region=$AwsRegion" `
    -backend-config="dynamodb_table=$LockTable" `
    -backend-config="encrypt=true"

$kmsValue = if ($EnableKms) { "true" } else { "false" }

Print-Info "Running terraform apply (this may take 10-30 minutes)..."
terraform apply -auto-approve `
    -var="base_domain=$Domain" `
    -var="aws_region=$AwsRegion" `
    -var="state_bucket=$StateBucket" `
    -var="lock_table=$LockTable" `
    -var="owner_email=$OwnerEmail" `
    -var="owner_password=$OwnerPassword" `
    -var="enable_kms_encryption=$kmsValue"

$CognitoClientId = terraform output -raw cognito_client_id
$FrontendBucket  = terraform output -raw frontend_bucket
Print-Success "Infrastructure deployed"

# Step 6: Build frontend
Print-Header "Step 6/8: Building frontend"

Set-Location "$ProjectRoot\frontend"

Print-Info "Writing .env file..."
@"
VITE_BASE_DOMAIN=$Domain
VITE_COGNITO_CLIENT_ID=$CognitoClientId
"@ | Set-Content -Path ".env" -Encoding UTF8

Print-Info "Installing npm dependencies..."
npm install

Print-Info "Building frontend..."
npm run build

Print-Success "Frontend built"

# Step 7: Upload to S3
Print-Header "Step 7/8: Uploading frontend to S3"

Print-Info "Syncing dist/ to s3://$FrontendBucket ..."
aws s3 sync dist/ "s3://$FrontendBucket" --delete

Print-Success "Frontend uploaded"

# Step 8: Done
Print-Header "Step 8/8: Setup complete!"

Write-Host ""
Write-Host "  +===================================================+" -ForegroundColor Green
Write-Host "  |            OpenCord is live!                       |" -ForegroundColor Green
Write-Host "  +===================================================+" -ForegroundColor Green
Write-Host ""

Print-Info "URL:         https://cdn.$Domain"
Print-Info "Owner email: $OwnerEmail"
Print-Info "Owner password: (the one you entered during setup)"
Write-Host ""
Print-Warn "If your domain was recently pointed to Route 53, DNS may"
Print-Warn "take a few minutes to propagate. If the site doesn't load"
Print-Warn "immediately, wait a bit and try again."
Write-Host ""
Print-Success "Done! Open https://cdn.$Domain in your browser to get started."

# --- Cleanup ---
# Offer to remove things this script installed/downloaded.

if ($script:RepoCloned -or $script:InstalledTools.Count -gt 0) {
    Write-Host ""
    Print-Header "Cleanup"
    Print-Info "The wizard installed some things on your system during this run."
    Write-Host ""
}

if ($script:RepoCloned) {
    if (Prompt-Confirm "Remove the downloaded OpenCord repository ($ProjectRoot)?" "N") {
        Remove-Item $ProjectRoot -Recurse -Force
        Print-Success "Downloaded repository removed"
    } else {
        Print-Info "Kept repository at $ProjectRoot"
    }
}

if ($script:InstalledTools.Count -gt 0) {
    Print-Info "The following tools were installed by this wizard:"
    foreach ($tool in $script:InstalledTools) {
        Print-Info "  - $($tool.Name)"
    }
    Write-Host ""
    if (Prompt-Confirm "Uninstall these tools?" "N") {
        foreach ($tool in $script:InstalledTools) {
            Print-Info "Removing $($tool.Name)..."
            try {
                winget uninstall --id $tool.WingetId --accept-source-agreements 2>$null | Out-Null
            } catch { }
        }
        Print-Success "Tools uninstalled"
    } else {
        Print-Info "Kept all installed tools."
    }
}
