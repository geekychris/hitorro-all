#!/bin/bash

# Improved script to update all Hitorro modules that already exist locally
# Provides better feedback and diagnostics

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# All Hitorro modules
MODULES=(
    "hitorro-util"
    "hitorro-base"
    "hitorro-unittime"
    "hitorro-features"
    "hitorro-jsonsql"
    "hitorro-jsonts-mongo"
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
    "hitorro-spring-boot"
    "hitorro-example-springboot"
    "hitorro-test"
)

# Default branch - changed to 'main' to match current repository state
DEFAULT_BRANCH="${1:-main}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Updating Hitorro Modules                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo -e "Target branch: ${CYAN}$DEFAULT_BRANCH${NC}"
echo ""

updated_count=0
skipped_count=0
error_count=0

for module in "${MODULES[@]}"; do
    if [ -d "$module/.git" ]; then
        cd "$module"
        
        # Get current branch
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        
        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "${YELLOW}[STASHING]${NC} $module"
            echo -e "  ${CYAN}→${NC} Uncommitted changes detected, stashing..."
            git stash push -m "auto-stash before update $(date +%Y-%m-%d_%H:%M:%S)" > /dev/null 2>&1 || true
            stashed=true
        else
            echo -e "${GREEN}[UPDATING]${NC} $module"
            stashed=false
        fi
        
        # Fetch latest changes
        git fetch origin > /dev/null 2>&1
        
        # Check if target branch exists
        if git show-ref --verify --quiet refs/heads/"$DEFAULT_BRANCH" || \
           git show-ref --verify --quiet refs/remotes/origin/"$DEFAULT_BRANCH"; then
            
            # Switch to target branch if not already on it
            if [ "$current_branch" != "$DEFAULT_BRANCH" ]; then
                echo -e "  ${CYAN}→${NC} Switching from $current_branch to $DEFAULT_BRANCH..."
                git checkout "$DEFAULT_BRANCH" > /dev/null 2>&1
            fi
            
            # Check if there are updates
            LOCAL=$(git rev-parse @)
            REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")
            
            if [ "$LOCAL" = "$REMOTE" ]; then
                echo -e "  ${GREEN}✓${NC} Already up to date"
                if [ "$stashed" = true ]; then
                    echo -e "  ${YELLOW}!${NC} Changes were stashed (use 'git stash pop' to restore)"
                fi
            else
                # Pull updates
                pull_output=$(git pull origin "$DEFAULT_BRANCH" 2>&1)
                if [ $? -eq 0 ]; then
                    # Count new commits
                    new_commits=$(echo "$pull_output" | grep -o '[0-9]* file' | grep -o '[0-9]*' | head -1)
                    echo -e "  ${GREEN}✓${NC} Updated successfully"
                    updated_count=$((updated_count + 1))
                    if [ "$stashed" = true ]; then
                        echo -e "  ${YELLOW}!${NC} Changes were stashed (use 'git stash pop' to restore)"
                    fi
                else
                    echo -e "  ${RED}✗${NC} Failed to pull updates"
                    echo -e "  ${RED}→${NC} $pull_output"
                    error_count=$((error_count + 1))
                fi
            fi
        else
            echo -e "  ${YELLOW}!${NC} Branch $DEFAULT_BRANCH doesn't exist"
            echo -e "  ${CYAN}→${NC} Staying on current branch: $current_branch"
            git pull > /dev/null 2>&1 || true
        fi
        
        cd ..
        echo ""
    else
        echo -e "${YELLOW}[SKIP]${NC} $module (not a Git repository or doesn't exist)"
        echo ""
        skipped_count=$((skipped_count + 1))
    fi
done

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                         SUMMARY                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

if [ $updated_count -gt 0 ]; then
    echo -e "${GREEN}✓ Updated:${NC} $updated_count module(s) had new changes"
fi
if [ $skipped_count -gt 0 ]; then
    echo -e "${YELLOW}⊘ Skipped:${NC} $skipped_count module(s)"
fi
if [ $error_count -gt 0 ]; then
    echo -e "${RED}✗ Errors:${NC} $error_count module(s) failed to update"
fi

echo ""

if [ $updated_count -eq 0 ] && [ $error_count -eq 0 ]; then
    echo -e "${GREEN}All modules were already up to date!${NC}"
    echo -e "If you expected updates, check:"
    echo -e "  1. Are you on the correct branch? Currently using: ${CYAN}$DEFAULT_BRANCH${NC}"
    echo -e "  2. Did you push changes from the other computer?"
    echo -e "  3. Run ${BLUE}./diagnose-modules.sh${NC} for detailed status"
elif [ $error_count -gt 0 ]; then
    echo -e "${RED}Some modules failed to update. Check the errors above.${NC}"
    exit 1
else
    echo -e "${GREEN}✓ All modules updated successfully!${NC}"
    echo -e "You may want to run: ${BLUE}mvn clean install${NC}"
fi

echo ""
