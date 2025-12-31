#!/bin/bash

# Simple script to update all Hitorro modules that already exist locally
# Use this when you've already cloned the modules and just want to pull updates

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# All Hitorro modules
MODULES=(
    "hitorro-util"
    "hitorro-base"
    "hitorro-unittime"
    "hitorro-features"
    "hitorro-jsonsql"
    "hitorro-objretrieval"
    "hitorro-text-core"
    "hitorro-text-persistence"
    "hitorro-basedms"
    "hitorro-dedupe"
    "hitorro-analysis"
    "hitorro-logdigest"
    "hitorro-dataaquisition"
    "hitorro-conversation"
    "hitorro-baseui"
    "hitorro-test"
)

# Default branch
DEFAULT_BRANCH="${1:-3.0.0}"

echo -e "${BLUE}Updating all Hitorro modules to branch: $DEFAULT_BRANCH${NC}"
echo ""

for module in "${MODULES[@]}"; do
    if [ -d "$module/.git" ]; then
        echo -e "${GREEN}[UPDATING]${NC} $module"
        cd "$module"

        # Stash and update
        git stash push -m "auto-stash before update" > /dev/null 2>&1 || true
        git fetch origin > /dev/null 2>&1
        git checkout "$DEFAULT_BRANCH" > /dev/null 2>&1
        git pull origin "$DEFAULT_BRANCH"

        cd ..
    else
        echo -e "${YELLOW}[SKIP]${NC} $module (not a Git repository or doesn't exist)"
    fi
done

echo -e "${GREEN}✓ All modules updated!${NC}"