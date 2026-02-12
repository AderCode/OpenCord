#Requires -Version 5.1
<#
.SYNOPSIS
    OpenCord Uninstall Wizard — Windows (PowerShell)
.DESCRIPTION
    Interactive wizard that tears down all AWS infrastructure deployed by
    OpenCord, optionally removes Terraform state storage, and cleans up
    local build artifacts.
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

# ─────────────────────────────────────────────
# Tracking
# ─────────────────────────────────────────────

$script:RepoCloned = $false

# ─────────────────────────────────────────────
# Repo resolution
# ─────────────────────────────────────────────

$RepoUrl = "https://github.com/AderCode/OpenCord.git"

function Resolve-ProjectRoot {
    param([string]$ScriptDir)

    # 1. Inside the repo at installers\windows\
    $candidate = (Resolve-Path "$ScriptDir\..\.." -ErrorAction SilentlyContinue).Path
    if ($candidate -and (Test-Path "$candidate\terraform\main.tf")) {
        Print-Success "Using repository at $candidate"
        return $candidate
    }

    # 2. Script copied to repo root
    if (Test-Path "$ScriptDir\terraform\main.tf") {
        Print-Success "Using repository at $ScriptDir"
        return $ScriptDir
    }

    # 3. Current working directory is the repo
    $cwd = (Get-Location).Path
    if (Test-Path "$cwd\terraform\main.tf") {
        Print-Success "Using repository at $cwd"
        return $cwd
    }

    # 4. OpenCord directory exists in current directory
    if (Test-Path "$cwd\OpenCord\terraform\main.tf") {
        $path = (Resolve-Path "$cwd\OpenCord").Path
        Print-Success "Using repository at $path"
        return $path
    }

    # 5. Clone the repo (needed for terraform config files)
    Print-Info "OpenCord repository not found locally. Downloading (needed for Terraform config)..."
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
Write-Host "  +=======================================+" -ForegroundColor Red
Write-Host "  |      OpenCord Uninstall Wizard        |" -ForegroundColor Red
Write-Host "  +=======================================+" -ForegroundColor Red
Write-Host ""

Print-Warn "This will destroy all AWS resources created by OpenCord."
Print-Warn "This action cannot be undone. All data (messages, users, etc.) will be permanently deleted."
Write-Host ""

if (-not (Prompt-Confirm "Are you sure you want to continue?")) {
    Print-Info "Aborted."
    exit 0
}

# Step 1: Check prerequisites
Print-Header "Step 1/6: Checking prerequisites"

if (-not (Assert-Command "aws")) {
    Print-Error "AWS CLI is not installed. It is required to tear down resources."
    exit 1
}
Print-Success "AWS CLI is installed"

if (-not (Assert-Command "terraform")) {
    Print-Error "Terraform is not installed. It is required to tear down resources."
    exit 1
}
Print-Success "Terraform is installed"

Print-Info "Locating OpenCord project files..."
$ProjectRoot = Resolve-ProjectRoot $ScriptDir

# Step 2: Verify AWS credentials
Print-Header "Step 2/6: Verifying AWS credentials"

try {
    $identity = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
    Print-Success "AWS credentials valid (Account: $($identity.Account))"
} catch {
    Print-Error "AWS credentials are not configured. Run 'aws configure' first."
    exit 1
}

# Step 3: Collect inputs
Print-Header "Step 3/6: Collecting configuration"

Print-Info "Enter the same values you used during installation."
Write-Host ""

$Domain = ""
while ([string]::IsNullOrWhiteSpace($Domain)) {
    $Domain = Prompt-Input "Domain name (e.g. mycommunity.chat)"
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        Print-Error "Domain name is required."
    }
}

$StateBucket = ""
while ([string]::IsNullOrWhiteSpace($StateBucket)) {
    $StateBucket = Prompt-Input "Terraform state S3 bucket name"
    if ([string]::IsNullOrWhiteSpace($StateBucket)) {
        Print-Error "State bucket name is required."
    }
}

$LockTable = Prompt-Input "Terraform lock DynamoDB table name" "opencord-tf-lock"
$AwsRegion = "us-east-1"

Write-Host ""
Print-Info "Configuration:"
Print-Info "  Domain:       $Domain"
Print-Info "  State bucket: $StateBucket"
Print-Info "  Lock table:   $LockTable"
Print-Info "  Region:       $AwsRegion"
Write-Host ""

Write-Host "This will permanently destroy all OpenCord infrastructure for $Domain." -ForegroundColor Red
if (-not (Prompt-Confirm "Type Y to confirm destruction")) {
    Print-Info "Aborted."
    exit 0
}

# Step 4: Terraform destroy
Print-Header "Step 4/6: Destroying infrastructure with Terraform"

Set-Location "$ProjectRoot\terraform"

Print-Info "Running terraform init..."
terraform init `
    -backend-config="bucket=$StateBucket" `
    -backend-config="key=opencord/terraform.tfstate" `
    -backend-config="region=$AwsRegion" `
    -backend-config="dynamodb_table=$LockTable" `
    -backend-config="encrypt=true"

Print-Info "Running terraform destroy (this may take several minutes)..."
terraform destroy -auto-approve `
    -var="base_domain=$Domain" `
    -var="aws_region=$AwsRegion" `
    -var="state_bucket=$StateBucket" `
    -var="lock_table=$LockTable" `
    -var="owner_email=placeholder@example.com" `
    -var="owner_password=Placeholder1"

Print-Success "All AWS infrastructure destroyed"

# Step 5: Clean up state storage
Print-Header "Step 5/6: Cleaning up Terraform state storage"

Print-Info "The S3 bucket and DynamoDB table used for Terraform state are not"
Print-Info "managed by Terraform itself. They can be deleted separately."
Write-Host ""

if (Prompt-Confirm "Delete the Terraform state S3 bucket ($StateBucket)?" "N") {
    Print-Info "Emptying bucket before deletion..."
    aws s3 rm "s3://$StateBucket" --recursive

    # Remove versioned objects and delete markers
    try {
        $versions = aws s3api list-object-versions --bucket $StateBucket --query "Versions[].{Key:Key,VersionId:VersionId}" --output json 2>$null | ConvertFrom-Json
        if ($versions -and $versions.Count -gt 0) {
            $deletePayload = @{ Objects = $versions; Quiet = $true } | ConvertTo-Json -Compress
            $deletePayload | aws s3api delete-objects --bucket $StateBucket --delete "file:///dev/stdin" 2>$null | Out-Null
        }
    } catch { }

    try {
        $markers = aws s3api list-object-versions --bucket $StateBucket --query "DeleteMarkers[].{Key:Key,VersionId:VersionId}" --output json 2>$null | ConvertFrom-Json
        if ($markers -and $markers.Count -gt 0) {
            $deletePayload = @{ Objects = $markers; Quiet = $true } | ConvertTo-Json -Compress
            $deletePayload | aws s3api delete-objects --bucket $StateBucket --delete "file:///dev/stdin" 2>$null | Out-Null
        }
    } catch { }

    aws s3api delete-bucket --bucket $StateBucket --region $AwsRegion
    Print-Success "S3 bucket deleted"
} else {
    Print-Info "Skipped - bucket '$StateBucket' was kept."
}

if (Prompt-Confirm "Delete the Terraform lock DynamoDB table ($LockTable)?" "N") {
    aws dynamodb delete-table --table-name $LockTable --region $AwsRegion | Out-Null
    Print-Success "DynamoDB table deleted"
} else {
    Print-Info "Skipped - table '$LockTable' was kept."
}

# Step 6: Clean up local files
Print-Header "Step 6/6: Cleaning up local files"

if (Prompt-Confirm "Remove local build artifacts and config? (frontend\.env, frontend\dist\, frontend\node_modules\, terraform\.terraform\)" "N") {
    $filesToRemove = @(
        "$ProjectRoot\frontend\.env"
    )
    $dirsToRemove = @(
        "$ProjectRoot\frontend\dist"
        "$ProjectRoot\frontend\node_modules"
        "$ProjectRoot\terraform\.terraform"
    )
    $lockFile = "$ProjectRoot\terraform\.terraform.lock.hcl"

    foreach ($f in $filesToRemove) {
        if (Test-Path $f) { Remove-Item $f -Force }
    }
    foreach ($d in $dirsToRemove) {
        if (Test-Path $d) { Remove-Item $d -Recurse -Force }
    }
    if (Test-Path $lockFile) { Remove-Item $lockFile -Force }

    Print-Success "Local files cleaned up"
} else {
    Print-Info "Skipped - local files were kept."
}

# Done
Write-Host ""
Write-Host "  +===================================================+" -ForegroundColor Green
Write-Host "  |         OpenCord has been removed.                 |" -ForegroundColor Green
Write-Host "  +===================================================+" -ForegroundColor Green
Write-Host ""

Print-Info "All AWS resources for $Domain have been destroyed."
Print-Info "If you kept the state bucket or lock table, you can delete them"
Print-Info "manually later from the AWS console."
Write-Host ""
Print-Success "Done. Thanks for using OpenCord!"

# --- Cleanup ---
if ($script:RepoCloned) {
    Write-Host ""
    Print-Header "Cleanup"
    if (Prompt-Confirm "Remove the downloaded OpenCord repository ($ProjectRoot)?" "N") {
        Remove-Item $ProjectRoot -Recurse -Force
        Print-Success "Downloaded repository removed"
    } else {
        Print-Info "Kept repository at $ProjectRoot"
    }
}
