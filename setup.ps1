param(
  [switch]$Force,
  [switch]$SkipBackup,
  [switch]$SkipSwarm,
  [switch]$SkipCass
)

$ErrorActionPreference = "Stop"
$ConfigDir = "$env:USERPROFILE\.config\opencode"
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step {
  param([string]$Message)
  Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-OK {
  Write-Host "  [OK]" -ForegroundColor Green
}

# --- Step 1: Backup ---
Write-Step "Backing up existing config"
if (Test-Path $ConfigDir) {
  $backup = "$ConfigDir-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  if (-not $SkipBackup) {
    Copy-Item -Recurse -Force $ConfigDir $backup
    Write-Host "  Backed up to $backup" -ForegroundColor Yellow
  } else {
    Write-Host "  Skipped (--SkipBackup)" -ForegroundColor Yellow
  }
}

# --- Step 2: Create config directory ---
Write-Step "Creating config directory"
New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
New-Item -ItemType Directory -Path "$ConfigDir\commands" -Force | Out-Null
New-Item -ItemType Directory -Path "$ConfigDir\plugin" -Force | Out-Null
New-Item -ItemType Directory -Path "$ConfigDir\agent" -Force | Out-Null
Start-Sleep -Milliseconds 100
Write-OK

# --- Step 3: Copy config files ---
Write-Step "Copying config files"
Copy-Item "$RepoDir\config\opencode.jsonc" "$ConfigDir\" -Force
Write-Host "  config/opencode.jsonc"
Copy-Item "$RepoDir\config\package.json" "$ConfigDir\" -Force
Write-Host "  config/package.json"
Copy-Item "$RepoDir\commands\*.md" "$ConfigDir\commands\" -Force
Write-Host "  commands/ ($(@(Get-ChildItem "$RepoDir\commands\*.md").Length) files)"
Copy-Item "$RepoDir\agent\*.md" "$ConfigDir\agent\" -Force
Write-Host "  agent/ ($(@(Get-ChildItem "$RepoDir\agent\*.md").Length) files)"
Copy-Item "$RepoDir\plugin\*" "$ConfigDir\plugin\" -Recurse -Force
Write-Host "  plugin/ ($(@(Get-ChildItem "$RepoDir\plugin" -Recurse).Length) files)"
if (Test-Path "$RepoDir\skills") {
  New-Item -ItemType Directory -Path "$ConfigDir\skills" -Force | Out-Null
  Copy-Item "$RepoDir\skills\*.md" "$ConfigDir\skills\" -Force
}
Write-OK

# --- Step 4: Install npm dependencies ---
Write-Step "Installing npm dependencies"
Push-Location $ConfigDir
try {
  if (Get-Command bun -ErrorAction SilentlyContinue) {
    bun install --quiet 2>&1 | Out-Null
    Write-Host "  bun install completed"
  } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install --no-optional 2>&1 | Out-Null
    Write-Host "  npm install completed"
  } else {
    Write-Host "  [WARN] No package manager found (bun or npm). Install manually." -ForegroundColor Yellow
  }
} finally {
  Pop-Location
}
Write-OK

# --- Step 5: Install swarm plugin ---
if (-not $SkipSwarm) {
  Write-Step "Installing opencode-swarm-plugin"
  try {
    $swarmCheck = & swarm --version 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host "  Already installed: $swarmCheck" -ForegroundColor Yellow
    }
  } catch {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
      npm install -g opencode-swarm-plugin 2>&1
      Write-Host "  opencode-swarm-plugin installed" -ForegroundColor Green
    }
  }
  Write-OK
} else {
  Write-Host "  Skipped (--SkipSwarm)" -ForegroundColor Yellow
}

# --- Step 6: Install CASS ---
if (-not $SkipCass) {
  Write-Step "Installing CASS (session search)"
  try {
    $cassCheck = & cass --version 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host "  Already installed: $cassCheck" -ForegroundColor Yellow
    }
  } catch {
    Write-Host "  Downloading from GitHub..." -ForegroundColor Gray
    $installScript = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Dicklesworthstone/coding_agent_session_search/main/install.ps1" -UseBasicParsing
    $scriptBlock = [scriptblock]::Create($installScript.Content)
    & $scriptBlock -EasyMode -Verify 2>&1
  }
  Write-OK
} else {
  Write-Host "  Skipped (--SkipCass)" -ForegroundColor Yellow
}

# --- Step 7: Add .local/bin to PATH ---
Write-Step "Ensuring PATH includes .local/bin"
$localBin = "$env:USERPROFILE\.local\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$localBin*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$localBin", "User")
  Write-Host "  Added $localBin to user PATH" -ForegroundColor Green
} else {
  Write-OK
}

Write-Host "`n" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNext steps:"
Write-Host "  1. Restart your terminal (or open a new tab)"
Write-Host "  2. Run: opencode"
Write-Host "  3. Inside OpenCode, try: /swarm ""your task"""
Write-Host "`nOptional:"
Write-Host "  - Install Ollama (for semantic memory): https://ollama.com/download/windows"
Write-Host "    Then: ollama pull mxbai-embed-large"
Write-Host "  - Install UBS (bug scanner): https://github.com/Dicklesworthstone/ultimate_bug_scanner"