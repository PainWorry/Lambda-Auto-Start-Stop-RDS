#!/usr/bin/env bash
# ==============================================================================
# AWS CloudOps & Cost Governance Suite - Git Push Helper Script
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "======================================================================"
echo "[INFO] AWS CloudOps & Cost Governance - GitHub Push Helper"
echo "======================================================================"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "[ERROR] Git is not installed on this machine."
    echo "[HINT] Please run: sudo apt update && sudo apt install -y git"
    exit 1
fi

echo "[OK] Git is installed ($(git --version))"

# Configure user if not set
CURRENT_USER=$(git config --global user.name || echo "")
if [ -z "$CURRENT_USER" ]; then
    echo "[CONFIG] Configuring Git global user..."
    git config --global user.name "CloudOps Engineer"
    git config --global user.email "cloudops@users.noreply.github.com"
fi

# Initialize repository if not already initialized
if [ ! -d ".git" ]; then
    echo "[INIT] Initializing local Git repository (branch: main)..."
    git init -b main
else
    echo "[OK] Git repository already initialized."
fi

# Stage and commit
echo "[STAGE] Staging files..."
git add .
if git status --porcelain | grep -q '^[MADRC]'; then
    git commit -m "feat: AWS CloudOps & Cost Governance Automation Suite"
    echo "[OK] Changes committed successfully."
else
    echo "[INFO] No changes to commit (already up to date)."
fi

# Check remote
EXISTING_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$EXISTING_REMOTE" ]; then
    echo ""
    echo "[INPUT] Enter your GitHub Repository HTTPS URL"
    echo "        (Example: https://github.com/<YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>.git):"
    read -r REPO_URL
    if [ -n "$REPO_URL" ]; then
        git remote add origin "$REPO_URL"
        echo "[OK] Added remote origin: $REPO_URL"
    else
        echo "[ERROR] No URL provided. Aborted."
        exit 1
    fi
else
    echo "[REMOTE] Current remote origin: $EXISTING_REMOTE"
fi

echo ""
echo "[INFO] Pushing to GitHub (using force push to overwrite initial repo template)..."
echo "[HINT] When prompted for password, paste your GitHub Personal Access Token (PAT: ghp_...)"
echo ""
git push -u origin main --force
echo ""
echo "[SUCCESS] Successfully pushed to GitHub!"
echo "======================================================================"
