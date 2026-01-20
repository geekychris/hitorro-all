# Troubleshooting Module Sync Issues

## Problem: "update-modules.sh doesn't sync new changes from another computer"

### Quick Diagnosis

Run the diagnostic script to check actual sync status:

```bash
./diagnose-modules.sh
```

This will show you:
- Which modules are synced ✓
- Which modules are behind remote (need updates) ✗
- Which modules have local changes ⚠
- Which modules have diverged 🔀

### Common Issues and Solutions

#### Issue 1: Wrong Branch

**Symptom**: Running `update-modules.sh` but not seeing changes you pushed from another computer

**Cause**: The default branch in `update-modules.sh` is `3.0.0`, but your repos might be on `main`

**Solution**:
```bash
# Specify the correct branch explicitly
./update-modules.sh main

# Or edit update-modules.sh line 35 to change default:
DEFAULT_BRANCH="${1:-main}"  # Changed from 3.0.0 to main
```

**Check your current branches**:
```bash
for module in hitorro-*; do 
    echo -n "$module: "
    cd $module && git branch --show-current && cd ..
done
```

#### Issue 2: Changes Not Actually Pushed

**Symptom**: You made changes on Computer A but they don't appear on Computer B

**Cause**: Changes were committed but not pushed to the remote repository

**Verification on Computer A**:
```bash
cd hitorro-util  # or any module
git status
# Look for: "Your branch is ahead of 'origin/main' by X commits"
```

**Solution on Computer A**:
```bash
# Push your changes
git push origin main
```

**Then on Computer B**:
```bash
./update-modules.sh main
```

#### Issue 3: Uncommitted Local Changes Blocking Update

**Symptom**: Update script reports "Already up to date" but you know there are remote changes

**Cause**: The script stashes changes but might fail silently if there are conflicts

**Solution**:
```bash
# Check what's uncommitted
cd hitorro-util
git status

# Option A: Commit your changes
git add .
git commit -m "WIP: my local changes"
git pull

# Option B: Stash and pull
git stash
git pull
git stash pop  # Re-apply your changes

# Option C: Discard local changes (⚠️ careful!)
git checkout .
git pull
```

#### Issue 4: Detached HEAD State

**Symptom**: Module is not on any branch

**Check**:
```bash
cd hitorro-util
git branch
# If you see "* (HEAD detached at xxx)" you're in detached HEAD state
```

**Solution**:
```bash
# Get back to main branch
git checkout main
git pull origin main
```

#### Issue 5: Remote URL Is Wrong

**Symptom**: Fetch/pull commands fail or access wrong repository

**Check**:
```bash
cd hitorro-util
git remote -v
# Should show: origin  git@github.com:geekychris/hitorro-util.git
```

**Solution**:
```bash
# Fix the remote URL
git remote set-url origin git@github.com:geekychris/hitorro-util.git
```

#### Issue 6: Git Authentication Issues

**Symptom**: Script hangs or fails with "Permission denied" or "Authentication failed"

**Solution**:
```bash
# Check SSH key is loaded
ssh-add -l

# If empty, add your key
ssh-add ~/.ssh/id_rsa  # or your key path

# Test GitHub connection
ssh -T git@github.com
# Should see: "Hi geekychris! You've successfully authenticated..."
```

### Verification Steps

After running update-modules.sh, verify the sync:

```bash
# Check all modules are up to date
./diagnose-modules.sh

# Check specific module
cd hitorro-util
git status
git log -3 --oneline
```

### Manual Module Update

If the script isn't working for a specific module, update manually:

```bash
cd hitorro-util

# Check current state
git status
git branch -vv

# Stash any local changes
git stash

# Fetch and pull
git fetch origin
git pull origin main

# Restore local changes if needed
git stash pop
```

### Understanding the Scripts

#### update-modules.sh
- **Purpose**: Quick update of existing modules
- **Default branch**: `3.0.0` (should probably be `main` for your setup)
- **What it does**:
  1. Stashes uncommitted changes
  2. Fetches from origin
  3. Checks out specified branch
  4. Pulls latest changes

#### diagnose-modules.sh
- **Purpose**: Show detailed sync status
- **Output**: Clear report of which modules need attention
- **Use case**: Run this first to understand what needs updating

### Best Practices

1. **Always specify the branch**:
   ```bash
   ./update-modules.sh main
   ```

2. **Check status before updating**:
   ```bash
   ./diagnose-modules.sh
   ```

3. **Commit or stash before updating**:
   ```bash
   git status  # in each module
   git commit -am "WIP" OR git stash
   ```

4. **Push from Computer A before pulling on Computer B**:
   ```bash
   # On Computer A (after making changes)
   git push origin main
   
   # On Computer B
   ./update-modules.sh main
   ```

5. **Keep the scripts updated**:
   - Edit `DEFAULT_BRANCH` in update-modules.sh to match your workflow
   - Keep module list in sync across scripts

### Example Workflow: Working Across Two Computers

#### On Computer A (where you make changes):
```bash
# 1. Make your changes in a module
cd hitorro-util
# ... edit files ...

# 2. Commit changes
git add .
git commit -m "Add new feature"

# 3. IMPORTANT: Push to remote
git push origin main

# 4. Update root repository too if needed
cd ..
git add .
git commit -m "Update with new changes"
git push origin main
```

#### On Computer B (where you want to sync):
```bash
# 1. Update root repository
git pull origin main

# 2. Update all modules
./update-modules.sh main

# 3. Verify everything is synced
./diagnose-modules.sh

# 4. Build if needed
mvn clean install
```

### When All Else Fails

Nuclear option (⚠️ destroys local changes):

```bash
# For a specific module
rm -rf hitorro-util
git clone git@github.com:geekychris/hitorro-util.git
cd hitorro-util
git checkout main

# Or use the checkout script to re-clone all
./checkout-modules.sh main
```

### Getting Help

If you're still having issues:

1. Run diagnostic and save output:
   ```bash
   ./diagnose-modules.sh > sync-status.txt
   ```

2. Check for specific errors:
   ```bash
   cd hitorro-util
   git fetch origin -v
   git pull origin main -v
   ```

3. Check network/authentication:
   ```bash
   ssh -T git@github.com
   git remote -v
   ```

4. Compare commits between computers:
   ```bash
   # On each computer
   cd hitorro-util
   git log --oneline -5
   git rev-parse HEAD
   ```
