#!/bin/bash

# Hitorro Modules Checkout Script
# This script clones/updates all Hitorro modules as independent repositories
# WITHOUT using Git submodules - each module remains fully independent
#
# Usage:
#   ./checkout-modules.sh           # Clone with default branch (main)
#   ./checkout-modules.sh 3.0.0     # Clone and checkout branch 3.0.0 (if it exists)
#   ./checkout-modules.sh develop   # Clone and checkout develop branch (if it exists)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Module configuration format: MODULE_NAME|GIT_URL
# Using SSH URLs to leverage your configured SSH key authentication
MODULES=(
    "hitorro-util|git@github.com:geekychris/hitorro-util.git"
    "hitorro-base|git@github.com:geekychris/hitorro-base.git"
    "hitorro-unittime|git@github.com:geekychris/hitorro-unittime.git"
    "hitorro-features|git@github.com:geekychris/hitorro-features.git"
    "hitorro-jsonsql|git@github.com:geekychris/hitorro-jsonsql.git"
    "hitorro-jsonts-mongo|git@github.com:geekychris/hitorro-jsonts-mongo.git"
    "hitorro-objretrieval|git@github.com:geekychris/hitorro-objretrieval.git"
    "hitorro-text-core|git@github.com:geekychris/hitorro-text-core.git"
    "hitorro-text-persistence|git@github.com:geekychris/hitorro-text-persistence.git"
    "hitorro-basedms|git@github.com:geekychris/hitorro-basedms.git"
    "hitorro-dedupe|git@github.com:geekychris/hitorro-dedupe.git"
    "hitorro-analysis|git@github.com:geekychris/hitorro-analysis.git"
    "hitorro-logdigest|git@github.com:geekychris/hitorro-logdigest.git"
    "hitorro-dataaquisition|git@github.com:geekychris/hitorro-dataaquisition.git"
    "hitorro-conversation|git@github.com:geekychris/hitorro-conversation.git"
    "hitorro-baseui|git@github.com:geekychris/hitorro-baseui.git"
    "hitorro-spring-boot|git@github.com:geekychris/hitorro-spring-boot.git"
    "hitorro-example-springboot|git@github.com:geekychris/hitorro-example-springboot.git"
    "hitorro-test|git@github.com:geekychris/hitorro-test.git"
    "hitorro-index|git@github.com:geekychris/hitorro-index.git"
    "hitorro-kvstore|git@github.com:geekychris/hitorro-kvstore.git"
    "hitorro-luceneviewer|git@github.com:geekychris/hitorro-luceneviewer.git"
)

# Default branch to use (leave empty to use repository default)
DEFAULT_BRANCH="${1:-main}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Hitorro Modules Checkout Script${NC}"
echo -e "${BLUE}========================================${NC}"
if [ -n "$DEFAULT_BRANCH" ]; then
    echo -e "Target branch: ${GREEN}${DEFAULT_BRANCH}${NC}"
else
    echo -e "Using repository default branches"
fi
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

            # Fetch latest changes
            git fetch origin > /dev/null 2>&1

            # Try to checkout desired branch if specified
            if [ -n "$DEFAULT_BRANCH" ]; then
                # Check if branch exists locally or remotely
                if git show-ref --verify --quiet refs/heads/"$DEFAULT_BRANCH" || \
                   git show-ref --verify --quiet refs/remotes/origin/"$DEFAULT_BRANCH"; then
                    git checkout "$DEFAULT_BRANCH" 2>&1 | sed 's/^/  → /'
                    git pull origin "$DEFAULT_BRANCH" 2>&1 | sed 's/^/  → /'
                else
                    echo -e "  ${YELLOW}→${NC} Branch $DEFAULT_BRANCH doesn't exist, staying on current branch"
                    git pull 2>&1 | sed 's/^/  → /'
                fi
            else
                # No specific branch, just pull current branch
                git pull 2>&1 | sed 's/^/  → /'
            fi

            cd ..
            echo -e "  ${GREEN}✓${NC} Updated successfully"
        else
            echo -e "${YELLOW}[SKIP]${NC} $module_name (exists but not a Git repository)"
        fi
    else
        # Module doesn't exist, clone it
        echo -e "${GREEN}[CLONE]${NC} $module_name (cloning repository...)"

        # Try to clone with specified branch first
        if [ -n "$DEFAULT_BRANCH" ]; then
            # Attempt to clone the specific branch
            if git clone -b "$DEFAULT_BRANCH" "$repo_url" "$module_name" 2>&1 | sed 's/^/  → /'; then
                echo -e "  ${GREEN}✓${NC} Cloned successfully on branch $DEFAULT_BRANCH"
            else
                # Branch doesn't exist, clone default and try to checkout/create branch
                echo -e "  ${YELLOW}→${NC} Branch $DEFAULT_BRANCH not found, cloning default branch..."
                if git clone "$repo_url" "$module_name" 2>&1 | sed 's/^/  → /'; then
                    cd "$module_name"
                    # Check if the branch exists remotely
                    if git ls-remote --heads origin "$DEFAULT_BRANCH" | grep -q "$DEFAULT_BRANCH"; then
                        git checkout "$DEFAULT_BRANCH" > /dev/null 2>&1
                        echo -e "  ${GREEN}✓${NC} Cloned and switched to existing branch $DEFAULT_BRANCH"
                    else
                        echo -e "  ${GREEN}✓${NC} Cloned successfully (branch $DEFAULT_BRANCH doesn't exist yet, staying on default branch)"
                    fi
                    cd ..
                else
                    echo -e "  ${RED}✗${NC} Failed to clone $module_name"
                    return 1
                fi
            fi
        else
            # No specific branch requested, just clone the default
            if git clone "$repo_url" "$module_name" 2>&1 | sed 's/^/  → /'; then
                echo -e "  ${GREEN}✓${NC} Cloned successfully"
            else
                echo -e "  ${RED}✗${NC} Failed to clone $module_name"
                return 1
            fi
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
        success_count=$((success_count + 1))
    else
        fail_count=$((fail_count + 1))
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