# Module Checkout and Update Scripts

## Quick Reference

### First Time Setup
```bash
./checkout-modules.sh
```

### Daily Development
```bash
./update-modules.sh
```

### Different Branch
```bash
./checkout-modules.sh branch-name
./update-modules.sh branch-name
```

## What These Scripts Do

**checkout-modules.sh**:
- Clones all Hitorro modules as independent Git repositories
- Updates existing modules (pulls latest changes)
- Stashes local changes before updating
- Can specify which branch to use (default: 3.0.0)

**update-modules.sh**:
- Updates only the modules that already exist
- Pulls latest changes from Git
- Stashes local changes before updating
- Faster than checkout-modules.sh for daily use

## Important Notes

- ❌ **NOT Git submodules** - each module is a fully independent repository
- ✅ Modules remain usable in other projects
- ✅ Standard Git operations work normally
- ✅ Simple and flexible workflow

## Next Steps

See `MODULE_MANAGEMENT.md` for detailed documentation.