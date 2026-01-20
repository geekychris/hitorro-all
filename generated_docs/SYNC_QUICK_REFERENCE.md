# Module Sync - Quick Reference Card

## 🚀 Quick Commands

### Check Sync Status
```bash
./diagnose-modules.sh
```
Shows which modules need updates, which are synced, etc.

### Update All Modules (Main Branch)
```bash
./update-modules.sh
# or explicitly:
./update-modules.sh main
```

### Update All Modules (Different Branch)
```bash
./update-modules.sh 3.0.0
./update-modules.sh develop
```

### Initial Checkout of All Modules
```bash
./checkout-modules.sh main
```

## 📋 Typical Workflow

### Scenario: Syncing changes from another computer

**On Computer A (where you made changes):**
```bash
cd hitorro-util                    # go to module
git add . && git commit -m "msg"   # commit changes
git push origin main               # ⚠️ IMPORTANT: push to remote!
```

**On Computer B (where you want to sync):**
```bash
./diagnose-modules.sh              # check what needs updating
./update-modules.sh main           # pull all updates
mvn clean install                  # rebuild if needed
```

## 🔍 Troubleshooting

### Module says "Already up to date" but I know there are changes

**Check if you actually pushed from the other computer:**
```bash
# On the computer where you made changes
cd hitorro-util
git status  # Look for "Your branch is ahead of 'origin/main'"
git push origin main  # Push if needed
```

### See what branch each module is on
```bash
for m in hitorro-*; do echo -n "$m: "; cd $m && git branch --show-current && cd ..; done
```

### Update a single module manually
```bash
cd hitorro-util
git stash                # save local changes
git pull origin main     # pull updates
git stash pop            # restore local changes
```

### Reset a module completely (⚠️ loses local changes)
```bash
rm -rf hitorro-util
git clone git@github.com:geekychris/hitorro-util.git
cd hitorro-util && git checkout main
```

## ⚠️ Common Mistakes

| Mistake | Result | Solution |
|---------|--------|----------|
| Forgot to push on Computer A | Computer B sees no updates | `git push origin main` on Computer A |
| Wrong branch specified | Script updates wrong branch | Use `./update-modules.sh main` |
| Uncommitted changes | Update might fail | Commit or stash first |
| Detached HEAD | Not on a branch | `git checkout main` |

## 📊 Understanding the Output

### diagnose-modules.sh Output

- `[SYNCED]` ✅ - Module is up to date
- `[SYNCED*]` ✅⚠️ - Up to date but has uncommitted changes
- `[BEHIND]` ❌ - Module needs update (run update-modules.sh)
- `[AHEAD]` ⚠️ - You have unpushed local commits
- `[DIVERGED]` ⚠️❌ - Local and remote have different commits (needs manual merge)
- `[MISSING]` ⚠️ - Module directory doesn't exist
- `[NOT GIT]` ⚠️ - Directory exists but isn't a git repo

### update-modules.sh Output

- `[UPDATING]` - Currently updating module
- `[STASHING]` - Saving uncommitted changes before update
- `[SKIP]` - Module doesn't exist or isn't a git repo
- `Already up to date` - No new changes from remote
- `✓ Updated successfully` - New changes were pulled

## 🛠️ Tools at Your Disposal

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `diagnose-modules.sh` | Check sync status | Before updating, when troubleshooting |
| `update-modules.sh` | Update existing modules | Daily workflow, after pulling from another computer |
| `checkout-modules.sh` | Clone/setup all modules | Initial setup, or to re-clone modules |
| `update-modules-improved.sh` | Enhanced update with better feedback | Alternative to update-modules.sh |

## 💡 Pro Tips

1. **Always run diagnose first**: `./diagnose-modules.sh` before updating
2. **Specify branch explicitly**: `./update-modules.sh main` (don't rely on defaults)
3. **Commit before updating**: Prevents merge conflicts
4. **Push immediately**: Don't wait - push changes right after committing
5. **One source of truth**: Always sync through Git, never copy files manually

## 🆘 Emergency Commands

### I messed everything up, start fresh
```bash
# Re-clone all modules (⚠️ loses local changes)
./checkout-modules.sh main
```

### Check if Git authentication works
```bash
ssh -T git@github.com
# Should say: "Hi geekychris! You've successfully authenticated"
```

### See what's different between local and remote
```bash
cd hitorro-util
git fetch origin
git log HEAD..origin/main --oneline  # Commits you're missing
git log origin/main..HEAD --oneline  # Commits you have but remote doesn't
```

## 📞 Still Having Issues?

1. Run: `./diagnose-modules.sh > status.txt`
2. Check the TROUBLESHOOTING_SYNC.md guide
3. Verify you pushed from the other computer: `git log origin/main -5`
