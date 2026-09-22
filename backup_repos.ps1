# ============================================================
# GitHub Repository Update Script
# Windows 11 / PowerShell
#
# WARNING:
# This script DISCARDS all local changes in the repositories
# and makes each repository exactly match its GitHub branch.
#
# It also removes files and directories that are not tracked
# by Git.
#
# The repositories are expected to be located in the directory
# where this script is RUN.
#
# If a repository does not exist in the current directory,
# it will be automatically cloned from:
#
#   https://github.com/andguerreiro/<repo>.git
# ============================================================

# ============================================================
# Base directory = current working directory
# ============================================================

$BaseDir = (Get-Location).Path

$GitHubUser = "andguerreiro"
$GitHubBaseUrl = "https://github.com/$GitHubUser"

$Repos = @(
    "isbn",
    "linux",
    "livrany",
    "games",
    "bibliany",
    "sebomenostelas",
    "kali",
    "win",
    "audio",
    "modico",
    "backup",
    "nixos"
)

$Successful = @()
$Failed = @()
$Cloned = @()

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "           GITHUB REPOSITORY UPDATE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Base directory: $BaseDir"
Write-Host "GitHub user:    $GitHubUser"
Write-Host ""
Write-Host "WARNING: Local changes will be discarded." -ForegroundColor Yellow
Write-Host "         Repositories will be synchronized with GitHub." -ForegroundColor Yellow
Write-Host ""
Write-Host "Missing repositories will be cloned automatically." -ForegroundColor Yellow
Write-Host ""

# ============================================================
# Process repositories
# ============================================================

foreach ($Repo in $Repos) {

    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Repository: $Repo" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

    $RepoPath = Join-Path $BaseDir $Repo
    $RepoUrl = "$GitHubBaseUrl/$Repo.git"

    # --------------------------------------------------------
    # Clone repository if it does not exist
    # --------------------------------------------------------

    if (-not (Test-Path $RepoPath)) {

        Write-Host ""
        Write-Host "Repository directory does not exist." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Cloning:" -ForegroundColor Cyan
        Write-Host "  $RepoUrl" -ForegroundColor Gray
        Write-Host ""

        git clone $RepoUrl $RepoPath

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "FAILED: Could not clone $Repo." -ForegroundColor Red
            $Failed += $Repo
            continue
        }

        Write-Host ""
        Write-Host "SUCCESS: $Repo cloned successfully." -ForegroundColor Green

        $Cloned += $Repo
    }

    # --------------------------------------------------------
    # Enter repository
    # --------------------------------------------------------

    Set-Location $RepoPath

    # --------------------------------------------------------
    # Check if this is a Git repository
    # --------------------------------------------------------

    if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
        Write-Host "FAILED: Directory exists but is not a Git repository." -ForegroundColor Red
        $Failed += $Repo
        Set-Location $BaseDir
        continue
    }

    # --------------------------------------------------------
    # Determine current branch
    # --------------------------------------------------------

    $Branch = (git branch --show-current).Trim()

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        Write-Host "FAILED: Could not determine current branch." -ForegroundColor Red
        $Failed += $Repo
        Set-Location $BaseDir
        continue
    }

    Write-Host "Current branch: $Branch" -ForegroundColor Gray

    # --------------------------------------------------------
    # Fetch latest changes from GitHub
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "Fetching latest changes from GitHub..." -ForegroundColor Cyan
    Write-Host ""

    git fetch origin $Branch

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "FAILED: git fetch failed for $Repo." -ForegroundColor Red
        $Failed += $Repo
        Set-Location $BaseDir
        continue
    }

    # --------------------------------------------------------
    # Discard ALL local changes
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "Discarding local changes..." -ForegroundColor Yellow
    Write-Host ""

    git reset --hard "origin/$Branch"

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "FAILED: Could not reset $Repo to origin/$Branch." -ForegroundColor Red
        $Failed += $Repo
        Set-Location $BaseDir
        continue
    }

    # --------------------------------------------------------
    # Remove untracked files and directories
    #
    # WARNING:
    # This permanently removes files inside the repository
    # that are not tracked by Git.
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "Removing untracked files..." -ForegroundColor Yellow
    Write-Host ""

    git clean -fd

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "FAILED: Could not remove untracked files for $Repo." -ForegroundColor Red
        $Failed += $Repo
        Set-Location $BaseDir
        continue
    }

    # --------------------------------------------------------
    # Success
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "SUCCESS: $Repo synchronized with GitHub." -ForegroundColor Green

    $Successful += $Repo

    Set-Location $BaseDir
}

# ============================================================
# Summary
# ============================================================

Write-Host ""
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                         SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Successfully updated:" -ForegroundColor Green

if ($Successful.Count -eq 0) {
    Write-Host "  None"
}
else {
    foreach ($Repo in $Successful) {
        Write-Host "  [OK] $Repo" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Cloned automatically:" -ForegroundColor Cyan

if ($Cloned.Count -eq 0) {
    Write-Host "  None"
}
else {
    foreach ($Repo in $Cloned) {
        Write-Host "  [CLONED] $Repo" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "Failed:" -ForegroundColor Red

if ($Failed.Count -eq 0) {
    Write-Host "  None"
}
else {
    foreach ($Repo in $Failed) {
        Write-Host "  [FAILED] $Repo" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Update process completed." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
