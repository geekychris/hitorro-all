#!/bin/bash

# Diagnostic script to check module sync status
# This will help identify issues with update-modules.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Hitorro Modules Diagnostic - Sync Status Check          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

total_modules=0
synced_modules=0
behind_modules=0
ahead_modules=0
diverged_modules=0
not_git_modules=0
missing_modules=0

for module in "${MODULES[@]}"; do
    total_modules=$((total_modules + 1))
    
    if [ ! -d "$module" ]; then
        echo -e "${RED}[MISSING]${NC} $module"
        echo -e "  ${YELLOW}→${NC} Directory does not exist"
        echo ""
        missing_modules=$((missing_modules + 1))
        continue
    fi
    
    if [ ! -d "$module/.git" ]; then
        echo -e "${YELLOW}[NOT GIT]${NC} $module"
        echo -e "  ${YELLOW}→${NC} Not a Git repository"
        echo ""
        not_git_modules=$((not_git_modules + 1))
        continue
    fi
    
    cd "$module"
    
    # Get current branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    # Check if branch tracks a remote
    remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    
    if [ -z "$remote_branch" ]; then
        echo -e "${YELLOW}[NO REMOTE]${NC} $module"
        echo -e "  ${CYAN}Branch:${NC} $current_branch"
        echo -e "  ${YELLOW}→${NC} Local branch not tracking any remote"
        echo ""
        cd ..
        continue
    fi
    
    # Fetch to get latest remote state
    git fetch origin > /dev/null 2>&1
    
    # Get commit info
    local_commit=$(git rev-parse HEAD)
    remote_commit=$(git rev-parse @{u} 2>/dev/null)
    
    # Count commits ahead/behind
    commits_behind=$(git rev-list HEAD..@{u} --count 2>/dev/null || echo "0")
    commits_ahead=$(git rev-list @{u}..HEAD --count 2>/dev/null || echo "0")
    
    # Check for uncommitted changes
    uncommitted_changes=$(git status --porcelain | wc -l | tr -d ' ')
    
    # Determine sync status
    if [ "$local_commit" = "$remote_commit" ]; then
        # In sync
        if [ "$uncommitted_changes" -gt 0 ]; then
            echo -e "${GREEN}[SYNCED*]${NC} $module"
            echo -e "  ${CYAN}Branch:${NC} $current_branch → $remote_branch"
            echo -e "  ${GREEN}✓${NC} Local is in sync with remote"
            echo -e "  ${YELLOW}⚠${NC} $uncommitted_changes uncommitted local changes"
        else
            echo -e "${GREEN}[SYNCED]${NC} $module"
            echo -e "  ${CYAN}Branch:${NC} $current_branch → $remote_branch"
            echo -e "  ${GREEN}✓${NC} Local is in sync with remote"
        fi
        synced_modules=$((synced_modules + 1))
    elif [ "$commits_behind" -gt 0 ] && [ "$commits_ahead" -eq 0 ]; then
        # Behind remote
        echo -e "${RED}[BEHIND]${NC} $module"
        echo -e "  ${CYAN}Branch:${NC} $current_branch → $remote_branch"
        echo -e "  ${RED}✗${NC} Local is $commits_behind commit(s) BEHIND remote"
        echo -e "  ${YELLOW}→${NC} Run: cd $module && git pull"
        if [ "$uncommitted_changes" -gt 0 ]; then
            echo -e "  ${YELLOW}⚠${NC} $uncommitted_changes uncommitted local changes (may need to stash)"
        fi
        behind_modules=$((behind_modules + 1))
    elif [ "$commits_ahead" -gt 0 ] && [ "$commits_behind" -eq 0 ]; then
        # Ahead of remote
        echo -e "${YELLOW}[AHEAD]${NC} $module"
        echo -e "  ${CYAN}Branch:${NC} $current_branch → $remote_branch"
        echo -e "  ${YELLOW}⚠${NC} Local is $commits_ahead commit(s) AHEAD of remote"
        echo -e "  ${YELLOW}→${NC} Run: cd $module && git push (if you want to push changes)"
        if [ "$uncommitted_changes" -gt 0 ]; then
            echo -e "  ${YELLOW}⚠${NC} $uncommitted_changes uncommitted local changes"
        fi
        ahead_modules=$((ahead_modules + 1))
    else
        # Diverged
        echo -e "${RED}[DIVERGED]${NC} $module"
        echo -e "  ${CYAN}Branch:${NC} $current_branch → $remote_branch"
        echo -e "  ${RED}✗${NC} Local has $commits_ahead commit(s) ahead, $commits_behind commit(s) behind"
        echo -e "  ${YELLOW}→${NC} Branches have diverged - may need manual merge/rebase"
        if [ "$uncommitted_changes" -gt 0 ]; then
            echo -e "  ${YELLOW}⚠${NC} $uncommitted_changes uncommitted local changes"
        fi
        diverged_modules=$((diverged_modules + 1))
    fi
    
    # Show last commit
    last_commit=$(git --no-pager log -1 --format="%h - %s (%cr)" 2>/dev/null)
    echo -e "  ${CYAN}Last commit:${NC} $last_commit"
    
    echo ""
    cd ..
done

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                         SUMMARY                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo -e "Total modules:     $total_modules"
echo -e "${GREEN}Synced:${NC}            $synced_modules"
if [ "$behind_modules" -gt 0 ]; then
    echo -e "${RED}Behind remote:${NC}     $behind_modules ${RED}← NEEDS UPDATE${NC}"
fi
if [ "$ahead_modules" -gt 0 ]; then
    echo -e "${YELLOW}Ahead of remote:${NC}   $ahead_modules"
fi
if [ "$diverged_modules" -gt 0 ]; then
    echo -e "${RED}Diverged:${NC}          $diverged_modules ${RED}← NEEDS ATTENTION${NC}"
fi
if [ "$not_git_modules" -gt 0 ]; then
    echo -e "${YELLOW}Not Git repos:${NC}     $not_git_modules"
fi
if [ "$missing_modules" -gt 0 ]; then
    echo -e "${RED}Missing:${NC}           $missing_modules"
fi

echo ""

# Recommendations
if [ "$behind_modules" -gt 0 ] || [ "$diverged_modules" -gt 0 ]; then
    echo -e "${YELLOW}RECOMMENDATIONS:${NC}"
    echo -e "  1. Run: ${BLUE}./update-modules.sh${NC} to update modules behind remote"
    echo -e "  2. For diverged modules, manually resolve conflicts"
    echo ""
    exit 1
elif [ "$ahead_modules" -gt 0 ]; then
    echo -e "${YELLOW}INFO:${NC}"
    echo -e "  Some modules have local commits not pushed to remote."
    echo -e "  This is normal if you've been developing locally."
    echo ""
    exit 0
else
    echo -e "${GREEN}✓ All modules are in sync!${NC}"
    echo ""
    exit 0
fi
