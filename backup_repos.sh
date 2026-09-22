#!/usr/bin/env bash

# ============================================================
# GitHub Repository Update Script
# Linux / WSL
#
# ATENÇÃO:
# Este script DESCARTA todas as alterações locais dos repositórios
# e deixa cada repositório exatamente igual à sua branch no GitHub.
#
# Se algum repositório não existir no BASE_DIR, ele será clonado
# automaticamente de:
#
#   https://github.com/andguerreiro/<repo>.git
#
# O script pode ser executado de qualquer diretório.
# ============================================================

REPOS=(
    "isbn"
    "linux"
    "livrany"
    "games"
    "bibliany"
    "sebomenostelas"
    "kali"
    "win"
    "audio"
    "modico"
    "backup"
    "nixos"
)

GITHUB_USER="andguerreiro"
GITHUB_BASE_URL="https://github.com/$GITHUB_USER"

# ============================================================
# Detect the directory where this script is located
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(basename "$SCRIPT_DIR")" == "GitHub" ]]; then
    BASE_DIR="$SCRIPT_DIR"

elif [[ -d "$SCRIPT_DIR/GitHub" ]]; then
    BASE_DIR="$SCRIPT_DIR/GitHub"

elif [[ -d "$(dirname "$SCRIPT_DIR")/GitHub" ]]; then
    BASE_DIR="$(cd -- "$(dirname "$SCRIPT_DIR")/GitHub" && pwd)"

else
    if [[ -d "/mnt/d/GitHub" ]]; then
        BASE_DIR="/mnt/d/GitHub"

    elif [[ -d "$HOME/GitHub" ]]; then
        BASE_DIR="$HOME/GitHub"

    else
        echo "ERROR: GitHub directory was not found."
        echo ""
        echo "Script location:"
        echo "  $SCRIPT_DIR"
        echo ""
        echo "The script expected GitHub to be located at:"
        echo "  $SCRIPT_DIR"
        echo "  $SCRIPT_DIR/GitHub"
        echo "  $(dirname "$SCRIPT_DIR")/GitHub"
        echo "  /mnt/d/GitHub"
        echo "  $HOME/GitHub"
        exit 1
    fi
fi

# Normalize the base directory path.
BASE_DIR="$(cd -- "$BASE_DIR" && pwd)"

SUCCESSFUL=()
FAILED=()
CLONED=()

echo ""
echo "============================================================"
echo "           GITHUB REPOSITORY UPDATE"
echo "============================================================"
echo ""
echo "Script location: $SCRIPT_DIR"
echo "Base directory:  $BASE_DIR"
echo ""
echo "GitHub user:     $GITHUB_USER"
echo ""
echo "WARNING: Local changes will be discarded."
echo "         Repositories will be synchronized with GitHub."
echo ""
echo "Missing repositories will be cloned automatically."
echo ""

cd -- "$BASE_DIR" || {
    echo "ERROR: Could not enter the GitHub directory."
    exit 1
}

for REPO in "${REPOS[@]}"; do

    echo ""
    echo "------------------------------------------------------------"
    echo "Repository: $REPO"
    echo "------------------------------------------------------------"

    REPO_PATH="$BASE_DIR/$REPO"
    REPO_URL="$GITHUB_BASE_URL/$REPO.git"

    # ========================================================
    # Clone repository if it does not exist
    # ========================================================

    if [[ ! -d "$REPO_PATH" ]]; then

        echo "Repository directory does not exist."
        echo ""
        echo "Cloning:"
        echo "  $REPO_URL"
        echo ""

        if git clone "$REPO_URL" "$REPO_PATH"; then
            echo ""
            echo "SUCCESS: $REPO cloned successfully."
            CLONED+=("$REPO")
        else
            echo ""
            echo "FAILED: Could not clone $REPO."
            FAILED+=("$REPO")
            continue
        fi
    fi

    # ========================================================
    # Enter repository
    # ========================================================

    cd -- "$REPO_PATH" || {
        echo "FAILED: Could not enter the repository directory."
        FAILED+=("$REPO")
        cd -- "$BASE_DIR"
        continue
    }

    # ========================================================
    # Check whether this is a Git repository
    # ========================================================

    if [[ ! -d ".git" ]]; then
        echo ""
        echo "FAILED: Directory exists but is not a Git repository."
        FAILED+=("$REPO")
        cd -- "$BASE_DIR"
        continue
    fi

    # ========================================================
    # Determine current branch
    # ========================================================

    BRANCH=$(git branch --show-current)

    if [[ -z "$BRANCH" ]]; then
        echo ""
        echo "FAILED: Could not determine current branch."
        FAILED+=("$REPO")
        cd -- "$BASE_DIR"
        continue
    fi

    echo ""
    echo "Current branch: $BRANCH"

    # ========================================================
    # Fetch latest changes from GitHub
    # ========================================================

    echo ""
    echo "Fetching latest changes from GitHub..."
    echo ""

    if ! git fetch origin "$BRANCH"; then
        echo ""
        echo "FAILED: git fetch failed for $REPO."
        FAILED+=("$REPO")
        cd -- "$BASE_DIR"
        continue
    fi

    # ========================================================
    # Discard ALL local modifications
    # ========================================================

    echo ""
    echo "Discarding local changes..."

    if ! git reset --hard "origin/$BRANCH"; then
        echo ""
        echo "FAILED: Could not reset $REPO to origin/$BRANCH."
        FAILED+=("$REPO")
        cd -- "$BASE_DIR"
        continue
    fi

    # ========================================================
    # Remove untracked files and directories
    # ========================================================
    #
    # This makes the local repository completely match GitHub.
    #
    # WARNING:
    # Any untracked files inside the repository will also be
    # permanently deleted.
    # ========================================================

    echo ""
    echo "Removing untracked files..."

    if ! git clean -fd; then
        echo ""
        echo "FAILED: Could not remove untracked files for $REPO."
        FAILED+=("$REPO")
        cd -- "$BASE_DIR"
        continue
    fi

    echo ""
    echo "SUCCESS: $REPO synchronized with GitHub."

    SUCCESSFUL+=("$REPO")

    cd -- "$BASE_DIR" || exit 1

done

# ============================================================
# Summary
# ============================================================

echo ""
echo ""
echo "============================================================"
echo "                         SUMMARY"
echo "============================================================"

echo ""
echo "Successfully updated:"

if [[ ${#SUCCESSFUL[@]} -eq 0 ]]; then
    echo "  None"
else
    for REPO in "${SUCCESSFUL[@]}"; do
        echo "  [OK] $REPO"
    done
fi

echo ""
echo "Cloned automatically:"

if [[ ${#CLONED[@]} -eq 0 ]]; then
    echo "  None"
else
    for REPO in "${CLONED[@]}"; do
        echo "  [CLONED] $REPO"
    done
fi

echo ""
echo "Failed:"

if [[ ${#FAILED[@]} -eq 0 ]]; then
    echo "  None"
else
    for REPO in "${FAILED[@]}"; do
        echo "  [FAILED] $REPO"
    done
fi

echo ""
echo "============================================================"
echo "Update process completed."
echo "============================================================"
echo ""
