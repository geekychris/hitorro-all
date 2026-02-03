# How to Remove hitorro-example-springboot from GitHub (hitorro-all)

## The Problem

Files from `hitorro-example-springboot` were committed and pushed to the `hitorro-all` repository on GitHub, when they should only be in their own separate repository.

## Solution Options

### Option 1: Remove from Git History (Recommended if no one else depends on these commits)

This completely removes the hitorro-example-springboot commits from hitorro-all's history:

```bash
cd /Users/chris/hitorro

# Create a backup branch first
git branch backup-before-filter

# Remove hitorro-example-springboot from all history
git filter-branch --tree-filter 'rm -rf hitorro-example-springboot' --prune-empty HEAD

# Or use the newer git-filter-repo (faster, cleaner):
# Install: brew install git-filter-repo
# git filter-repo --path hitorro-example-springboot --invert-paths

# Force push to update GitHub (WARNING: rewrites history)
git push origin main --force
# or: git push origin master --force
```

**⚠️ Warning**: This rewrites git history. Anyone who has cloned the repo needs to re-clone or reset.

### Option 2: Revert the Commit (Safest - keeps history)

This creates a new commit that removes the files but keeps the history:

```bash
cd /Users/chris/hitorro

# Find the commit that added hitorro-example-springboot files
git log --oneline --all -- hitorro-example-springboot/ | head -5

# Revert that commit (replace COMMIT_HASH with actual hash)
git revert COMMIT_HASH

# Or manually remove and commit:
git rm -r hitorro-example-springboot/
git commit -m "Remove hitorro-example-springboot (moved to separate repository)"

# Push the revert
git push origin main
```

### Option 3: Manual Removal (Simplest)

Just delete the directory and commit:

```bash
cd /Users/chris/hitorro

# Ensure it's in .gitignore (already done)
cat .gitignore | grep hitorro-example-springboot

# Remove from repository
git rm -r hitorro-example-springboot/

# Commit the removal
git commit -m "Remove hitorro-example-springboot directory

This directory is a separate git repository and should not be
tracked in hitorro-all. It has been moved to its own repository."

# Push to GitHub
git push origin main
```

## After Cleanup

1. **Verify on GitHub**: Check github.com to confirm hitorro-example-springboot is gone
2. **Keep local structure**: Your local `/Users/chris/hitorro/hitorro-example-springboot/` stays with its own git
3. **Update .gitignore**: Already done - it will be ignored from now on

## If Others Have Cloned

After using Option 1 (force push), tell collaborators to:

```bash
cd their-hitorro-all-clone
git fetch origin
git reset --hard origin/main  # or origin/master
```

## Verify

After cleanup:

```bash
# Check hitorro-all on GitHub
# Should NOT contain hitorro-example-springboot/

# Check local hitorro-example-springboot
cd /Users/chris/hitorro/hitorro-example-springboot
git status
# Should show its own git repository with Docker/React commits
```

## Recommended Approach

For a clean repository without the accidental files:

```bash
cd /Users/chris/hitorro

# 1. Make sure hitorro-example-springboot is ignored
echo "hitorro-example-springboot/" >> .gitignore

# 2. Remove from git but keep locally
git rm -r --cached hitorro-example-springboot/

# 3. Commit the removal
git commit -m "Remove hitorro-example-springboot from hitorro-all

This is a separate repository and should not be tracked here."

# 4. Push to GitHub
git push origin main
```

This removes it going forward but keeps the history (safest for collaboration).
