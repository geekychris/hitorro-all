# Module Management Guide

## Overview

Hitorro modules are managed as **independent Git repositories** using shell scripts, **NOT** as Git submodules. This approach:
- ✅ Keeps each module fully independent and reusable
- ✅ Allows modules to be used in other projects without Git submodule complexities
- ✅ Provides simple checkout/update workflows
- ✅ Maintains clean separation of concerns

## Quick Start

### Initial Setup (Check out all modules)

```bash
# Clone/update all modules on the 3.0.0 branch
./checkout-modules.sh

# Or specify a different branch
./checkout-modules.sh main
```

### Daily Updates

```bash
# Pull latest changes for all modules
./update-modules.sh

# Or specify a different branch
./update-modules.sh main
```

## Script Details

### Option 1: checkout-modules.sh (Full Setup)

**Purpose**: Clone missing modules or update existing ones

**Usage**:
```bash
./checkout-modules.sh [branch-name]
```

**Behavior**:
- If a module doesn't exist: Clones it from Git
- If a module exists: Stashes local changes, switches to specified branch, pulls updates
- Provides detailed color-coded output

**Example**:
```bash
./checkout-modules.sh 3.0.0
```

### Option 2: update-modules.sh (Quick Update)

**Purpose**: Update all existing modules (skips cloning)

**Usage**:
```bash
./update-modules.sh [branch-name]
```

**Behavior**:
- Only processes modules that already exist
- Stashes local changes, switches to specified branch, pulls updates
- Simple, quiet output

**Example**:
```bash
./update-modules.sh
```

## Configuring Module URLs

Edit `checkout-modules.sh` to set your actual Git repository URLs:

```bash
MODULES=(
    "hitorro-util|https://github.com/geekychris/hitorro-util.git"
    "hitorro-base|https://github.com/geekychris/hitorro-base.git"
    # ... etc
)
```

Format: `MODULE_NAME|GIT_URL`

## Workflow Examples

### Scenario 1: Fresh Development Environment

```bash
# 1. Clone the hitorro-root repository
git clone https://github.com/geekychris/hitorro-root.git
cd hitorro-root

# 2. Check out all dependent modules on version 3.0.0
./checkout-modules.sh 3.0.0

# 3. Build the project
mvn clean install

# 4. Start developing
# You can now edit any module and they're all available for building
```

### Scenario 2: Update to Latest Changes

```bash
# Pull updates for root project
git pull origin 3.0.0

# Update all modules
./update-modules.sh 3.0.0

# Rebuild
mvn clean install
```

### Scenario 3: Work on Different Branch

```bash
# Checkout development branch in all repos
./checkout-modules.sh dev

# Or update only (if already cloned)
./update-modules.sh dev
```

### Scenario 4: Use Only Specific Modules

```bash
# Skip update scripts - just clone what you need manually
git clone https://github.com/geekychris/hitorro-util.git
git clone https://github.com/geekychris/hitorro-base.git

# Or use the scripts and delete modules you don't need
./checkout-modules.sh 3.0.0
rm -rf hitorro-baseui hitorro-conversation  # remove unwanted modules
```

## Comparison with Git Submodules

| Aspect | This Approach (Shell Scripts) | Git Submodules |
|--------|-------------------------------|----------------|
| **Module Independence** | ✅ Fully independent | ⚠️ Coupled to parent repo |
| **Use in Other Projects** | ✅ Simple clone and use | ❌ Must be submodule or separate clone |
| **Learning Curve** | ✅ Simple Git operations | ❌ Complex submodule commands |
| **Performance** | ✅ Standard Git operations | ⚠️ Can be slower |
| **Merge Conflicts** | ✅ Standard Git merges | ⚠️ Submodule-specific issues |
| **Version Tracking** | ✅ `.gitmodules` equivalent is the script | ✅ `.gitmodules` |
| **Partial Checkout** | ✅ Easy (clone only what you need) | ⚠️ More complex |
| **Repository URL Changes** | ✅ Edit script once | ❌ Must update `.gitmodules` |

## Why Not Git Submodules?

Git submodules create tight coupling and complexity:

### Problems with Git Submodules

1. **Forced coupling**: Modules must be submodules in every project
   ```bash
   # Other projects must use submodules to use your modules
   git submodule add https://github.com/geekychris/hitorro-util.git
   ```

2. **Complex commands**: Special submodule commands required
   ```bash
   git submodule update --init --recursive
   git submodule foreach git pull origin master
   ```

3. **Merge/conflict issues**: Submodule pointer references can be tricky
   ```bash
   # Submodule commits can get out of sync
   # Detached HEAD states common
   ```

4. **Independent usage**: Harder to use modules independently
   ```bash
   # Can't just "git clone hitorro-util" and expect it to work nicely
   ```

### Benefits of This Approach

1. **Real independence**: Each module is a standalone Git repository
   ```bash
   # Anyone can clone and use hitorro-util
   git clone https://github.com/geekychris/hitorro-util.git
   cd hitorro-util
   mvn package  # Just works!
   ```

2. **Simple Git operations**: No special commands needed
   ```bash
   # Just normal Git operations
   cd hitorro-util
   git pull
   git checkout feature-branch
   ```

3. **Flexibility**: Use modules however/wherever you want
   ```bash
   # Use in any project, any way you want
   # As normal deps in pom.xml:
   #   <dependency>
   #     <groupId>com.hitorro</groupId>
   #     <artifactId>hitorro-util</artifactId>
   #     <version>3.0.0</version>
   #   </dependency>
   ```

4. **Easy to start**: Clone modules where convenient
   ```bash
   # In this workspace:
   ./checkout-modules.sh

   # In another project:
   mkdir libs && cd libs
   git clone https://github.com/geekychris/hitorro-util.git
   ```

## Advanced: Custom Workspaces

You can create different workspace configurations:

### Option A: Minimal Workspace

```bash
# Only include what you need
mkdir hitorro-minimal
cd hitorro-minimal

# Copy checkout-modules.sh and edit MODULES array
# Only include: hitorro-util, hitorro-base, hitorro-app

./checkout-modules.sh
```

### Option B: Feature Workspace

```bash
# Workspace for specific feature development
mkdir hitorro-text-workspace
cd hitorro-text-workspace

# Clone only text-related modules
git clone https://github.com/geekychris/hitorro-text-core.git
git clone https://github.com/geekychris/hitorro-text-persistence.git
git clone https://github.com/geekychris/hitorro-util.git  # required dependency

# Create a minimal pom.xml referencing these
```

### Option C: Development vs Production

```bash
# Development: Use source code modules
./checkout-modules.sh dev

# Production: Use published artifacts from Maven repo
# No need for script! Just add dependencies to pom.xml
```

## Troubleshooting

### Script Not Executable

```bash
chmod +x checkout-modules.sh
chmod +x update-modules.sh
```

### Wrong Branch

```bash
# Update modules to correct branch
./update-modules.sh correct-branch-name
```

### Module Already Exists But Not a Git Repo

If you have directories that aren't Git repos:
```bash
# Remove the directory and let the script clone it
rm -rf hitorro-util
./checkout-modules.sh
```

### Merge Conflicts During Update

The script will stash changes before updating:
```bash
# To restore stashed changes
cd hitorro-util
git stash list
git stash pop stash@{0}
```

### Network Issues

If cloning fails due to network issues:
```bash
# The script will report failures and continue
# Just re-run it:
./checkout-modules.sh
```

## Best Practices

1. **Commit the scripts** - Keep `checkout-modules.sh` and `update-modules.sh` in your root repository
2. **Document branch names** - Add comments indicating which branches to use
3. **Version with modules** - Tag root repo alongside module versions for coordination
4. **Use branch names wisely** - Use stable branches (e.g., `3.0.0`, `3.1.0`) for production
5. **Keep URLs updated** - Update script if module repository URLs change
6. **README in each module** - Document how to use each module independently

## Summary

This shell script approach provides:
- ✅ **True module independence** - each module is a standalone Git repo
- ✅ **Simple workflow** - standard Git operations
- ✅ **Flexibility** - easy to customize workspaces
- ✅ **No submodule complexity** - avoids Git submodule pitfalls
- ✅ **Easy external usage** - other projects can clone and use modules directly

The scripts are essentially a "dynamic .gitmodules" that executes shell commands instead of Git submodule commands, giving you the benefits of coordinated development without the coupling of Git submodules.