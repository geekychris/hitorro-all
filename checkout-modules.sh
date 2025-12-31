#!/bin/bash

# Hitorro Modules Checkout Script
# This script clones/updates all Hitorro modules as independent repositories
# WITHOUT using Git submodules - each module remains fully independent

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Module configuration format: MODULE_NAME|GIT_URL
# Replace with actual Git repository URLs
MODULES=(
    "hitorro-util|https://github.com/geekychris/hitorro-util.git"
    "hitorro-base|https://github.com/geekychris/hitorro-base.git"
    "hitorro-unittime|https://github.com/geekychris/hitorro-unittime.git"
    "hitorro-features|https://github.com/geekychris/hitorro-features.git"
    "hitorro-jsonsql|https://github.com/geekychris/hitorro-jsonsql.git"
    "hitorro-objretrieval|https://github.com/geekychris/hitorro-objretrieval.git"
    "hitorro-text-core|https://github.com/geekychris/hitorro-text-core.git"
    "hitorro-text-persistence|https://github.com/geekychris/hitorro-text-persistence.git"
    "hitorro-basedms|https://github.com/geekychris/hitorro-basedms.git"
    "hitorro-dedupe|https://github.com/geekychris/hitorro-dedupe.git"
    "hitorro-analysis|https://github.com/geekychris/hitorro-analysis.git"
    "hitorro-logdigest|https://github.com/geekychris/hitorro-logdigest.git"
    "hitorro-dataaquisition|https://github.com/geekychris/hitorro-dataaquisition.git"
    "hitorro-conversation|https://github.com/geekychris/hitorro-conversation.git"
    "hitorro-baseui|https://github.com/geekychris/hitorro-baseui.git"
    "hitorro-test|https://github.com/geekychris/hitorro-test.git"
)

# Default branch to use
DEFAULT_BRANCH="${1:-3.0.0}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Hitorro Modules Checkout Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Target branch: ${GREEN}${DEFAULT_BRANCH}${NC}"
echo ""

# Function to checkout or update a module
process_module() {
    local module_name="$1"
    local repo_url="$2"

    if [ -d "$module_name" ]; then
        # Module exists, update it
        if [ -d "$module_name/.git" ]; then
            echo -e "${YELLOW}[UPDATE]${NC} $module_name (pulling updates...)"

            cd "$module_name"

            # Stash any local changes
            if [ -n "$(git status --porcelain)" ]; then
                echo -e "  → Stashing local changes..."
                git stash push -m "auto-stash before checkout" > /dev/null 2>&1 || true
            fi

            # Checkout desired branch
            git fetch origin > /dev/null 2>&1
            git checkout "$DEFAULT_BRANCH" 2>&1 | sed 's/^/  → /'

            # Pull latest changes
            git pull origin "$DEFAULT_BRANCH" 2>&1 | sed 's/^/  → /'

            cd ..
            echo -e "  ${GREEN}✓${NC} Updated successfully"
        else
            echo -e "${YELLOW}[SKIP]${NC} $module_name (exists but not a Git repository)"
        fi
    else
        # Module doesn't exist, clone it
        echo -e "${GREEN}[CLONE]${NC} $module_name (cloning repository...)"

        if git clone -b "$DEFAULT_BRANCH" "$repo_url" "$module_name" 2>&1 | sed 's/^/  → /'; then
            echo -e "  ${GREEN}✓${NC} Cloned successfully"
        else
            echo -e "  ${RED}✗${NC} Failed to clone $module_name"
            return 1
        fi
    fi
    echo ""
}

# Process all modules
success_count=0
fail_count=0

for module_config in "${MODULES[@]}"; do
    IFS='|' read -r module_name repo_url <<< "$module_config"

    if process_module "$module_name" "$repo_url"; then
        ((success_count++))
    else
        ((fail_count++))
    fi
done

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Successfully processed:${NC} $success_count modules"
if [ $fail_count -gt 0 ]; then
    echo -e "${RED}Failed:${NC} $fail_count modules"
fi
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}All modules checked out!${NC}"
    echo -e "You can now run: ${BLUE}mvn clean install${NC}"
    exit 0
else
    echo -e "${YELLOW}Some modules failed. Please check the errors above.${NC}"
    exit 1
fi