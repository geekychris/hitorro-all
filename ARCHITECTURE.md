# Hitorro Project Architecture

## Overview
This workspace uses a **flexible aggregation pattern** where sub-modules remain independent while allowing convenient multi-module builds and runtime composition.

## Structure Diagram

```
hitorro/ (workspace root)
├── pom.xml (hitorro-root)            ← Aggregator only, no parent relationship
│   └── <modules> list only
│
├── hitorro-util/                      ← Independent module
│   └── pom.xml (standalone)
│
├── hitorro-base/                      ← Independent module
│   └── pom.xml (standalone)
│
├── hitorro-unittime/                  ← Independent module
│   └── pom.xml (standalone)
│
├── ... (12 more independent modules)
│
└── hitorro-app/                       ← Runtime aggregator module
    └── pom.xml (depends on all modules for runtime classpath)
```

## Module Independence

### Each Sub-Module Is:
- ✅ **Standalone** - has its own groupId/artifactId/version
- ✅ **Self-contained** - declares all its own dependencies
- ✅ **Repository-independent** - can live in separate Git repos
- ✅ **Reusable** - can be used individually in other projects
- ✅ **Not coupled to root** - no `<parent>` reference

### The Root POM (`hitorro-root`):
- 🏗️ **Pure aggregator** - `<packaging>pom</packaging>`
- 🔧 **Build convenience** - `mvn install` builds all modules
- 📋 **Dependency suggestions** - `<dependencyManagement>` (optional to use)
- ❌ **Not a parent** - modules don't inherit from it

### The App Module (`hitorro-app`):
- 🎯 **Runtime composition** - bundles modules together
- 🚀 **Execution entry point** - configured with main class
- 📦 **Classpath provider** - includes all modules for IntelliJ
- ⚙️ **Customizable** - edit dependencies to change module set

## Build Modes

### Mode 1: Build All Modules (Reactor Build)
```bash
cd /Users/chris/hitorro
mvn clean install
```
Maven builds all modules in dependency order.

### Mode 2: Build Single Module
```bash
cd /Users/chris/hitorro/hitorro-util
mvn clean install
```
Each module can be built independently.

### Mode 3: Build App with Dependencies
```bash
cd /Users/chris/hitorro/hitorro-app
mvn clean package
```
Builds the app module and pulls in all module dependencies.

## Usage Patterns

### Pattern 1: Use in Another Project
Add only what you need to your external project's POM:

```xml
<dependencies>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-util</artifactId>
        <version>3.0.0</version>
    </dependency>
    <!-- Add only the modules you need -->
</dependencies>
```

### Pattern 2: Run in This Workspace (IntelliJ)
1. Select `hitorro-app` as the module
2. Choose your main class
3. All modules are on the classpath

### Pattern 3: Custom Runtime Composition
Create `hitorro-app-custom/pom.xml`:

```xml
<dependencies>
    <!-- Include only specific modules -->
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-util</artifactId>
        <version>3.0.0</version>
    </dependency>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-base</artifactId>
        <version>3.0.0</version>
    </dependency>
    <!-- Omit heavy modules like baseui, text-core, etc. -->
</dependencies>
```

## Dependency Flow

```
┌─────────────────────────────────────────────────┐
│  hitorro-root (aggregator)                      │
│  - Defines build order                          │
│  - Provides <dependencyManagement> (optional)   │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌──────────────┐            ┌──────────────┐
│ hitorro-util │            │ hitorro-base │
│ (standalone) │◄───────────│ (standalone) │
└──────────────┘  depends   └──────────────┘
        ▲                           ▲
        │                           │
        │         depends           │
        └───────────┬───────────────┘
                    │
            ┌───────────────┐
            │ hitorro-app   │
            │ (aggregator)  │
            └───────────────┘
```

## Key Benefits

### For Development in This Workspace:
- Single Maven command builds everything
- IntelliJ understands module relationships
- Easy to run applications needing multiple modules

### For Using Modules Elsewhere:
- No coupling to root POM
- Pick and choose which modules to use
- Clean dependency declarations
- Can be published to Maven Central independently

### For Repository Management:
- Each module can be in its own Git repo
- Or all in one monorepo (current setup)
- Git submodules could be used if desired
- No forced directory structure

## Comparison with Traditional Parent-Child

### Traditional (Parent-Child):
```
parent-pom
  ├── (child inherits from parent)
  ├── child-module-1 ──> must reference parent
  └── child-module-2 ──> must reference parent
```
**Problem**: Tight coupling - child can't be used without parent

### This Architecture (Aggregator):
```
aggregator-pom
  ├── (lists modules for build convenience)
  ├── independent-module-1 ──> no parent reference
  └── independent-module-2 ──> no parent reference

runtime-aggregator
  ├── depends on: independent-module-1
  └── depends on: independent-module-2
```
**Solution**: Loose coupling - modules stay independent

## Migration Guide

If you later want to use modules in separate repositories:

1. **Move the module** to its own repository
2. **Publish to Maven repository** (local or remote)
3. **Update hitorro-app** to depend on published artifact:
   ```xml
   <dependency>
       <groupId>com.hitorro</groupId>
       <artifactId>hitorro-util</artifactId>
       <version>3.0.0</version>
       <!-- Now fetches from Maven repo instead of local build -->
   </dependency>
   ```
4. **Remove from root POM** `<modules>` section
5. **Done** - no other changes needed!

## Summary

This architecture provides:
- ✅ **Flexibility** - use modules independently or together
- ✅ **Simplicity** - no complex parent-child inheritance
- ✅ **Portability** - modules work anywhere
- ✅ **Convenience** - easy multi-module builds when needed
- ✅ **Scalability** - add/remove modules without breaking others
