# IntelliJ Run Configuration Guide

## Problem Summary
The root `pom.xml` has `<packaging>pom</packaging>`, which means it's purely an aggregator project that doesn't produce any executable JAR. You cannot run classes directly from the "hitorro-root" module in IntelliJ.

## Solution Architecture
A new **independent** `hitorro-app` module has been created that:
- **Aggregates all Hitorro sub-modules as runtime dependencies**
- **Does NOT force parent-child relationships** - all sub-modules remain independent repositories
- Provides a unified classpath for running applications that need multiple modules

This allows you to:
- Keep sub-modules as separate, independent repositories
- Use them individually in other projects
- Also have a convenient way to run applications that need multiple modules together

## How to Configure IntelliJ Run Configuration

### Step 1: Reload Maven Project
1. Right-click on the root `pom.xml` in IntelliJ
2. Select **Maven → Reload Project**
3. Wait for IntelliJ to reimport all modules

### Step 2: Create Run Configuration
1. Go to **Run → Edit Configurations...**
2. Click the **+** button and select **Application**
3. Configure as follows:
   - **Name**: `CommandLine` (or whatever you prefer)
   - **Main class**: `com.hitorro.util.cmdline.CommandLine`
   - **Module**: Select **hitorro-app** from the dropdown
   - **Working directory**: `$MODULE_WORKING_DIR$` or `/Users/chris/hitorro`
   - **Use classpath of module**: **hitorro-app**

### Step 3: Run Your Application
Click the **Run** button. The application will now have access to all classes from all sub-modules.

## What Changed

### 1. Sub-Modules Remain Independent
**All 16 sub-modules are standalone** and do NOT have parent references:
- `hitorro-util`, `hitorro-base`, `hitorro-unittime`, `hitorro-features`
- `hitorro-jsonsql`, `hitorro-objretrieval`, `hitorro-text-core`, `hitorro-text-persistence`
- `hitorro-basedms`, `hitorro-dedupe`, `hitorro-analysis`, `hitorro-logdigest`
- `hitorro-dataaquisition`, `hitorro-conversation`, `hitorro-baseui`, `hitorro-test`

Each can be:
- Used independently in other projects
- Maintained in separate Git repositories
- Published to Maven repositories individually
- Built standalone without the root POM

### 2. Root POM as Aggregator Only
The root `pom.xml` serves ONLY as a **multi-module build aggregator**:
- Lists all modules in `<modules>` section
- Allows `mvn clean install` to build all modules in dependency order
- Does NOT impose parent-child relationships
- Provides shared `<dependencyManagement>` for convenience (optional to use)

### 3. New Application Module
Created `hitorro-app/pom.xml` as an **independent runtime aggregator**:
- Depends on all 16 Hitorro modules as regular dependencies
- Sets `com.hitorro.util.cmdline.CommandLine` as the main class
- Provides a single classpath that includes all modules
- Also an independent module (no parent reference)

## Benefits

✅ **Sub-modules stay independent** - can be used separately in other projects  
✅ **Flexible runtime composition** - choose which modules to include by editing hitorro-app dependencies  
✅ **Single run configuration** for applications needing all modules  
✅ **Maven reactor builds** - `mvn clean install` builds all modules in the correct order  
✅ **IntelliJ integration** - proper module recognition and code completion  
✅ **Repository independence** - each module can be in its own Git repository  

## Using Modules in Different Contexts

### Scenario 1: Use a subset of modules in another project
Just add the specific modules you need as dependencies:
```xml
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
```

### Scenario 2: Run an application needing all modules (this workspace)
Use the `hitorro-app` module in your IntelliJ run configuration.

### Scenario 3: Create a different runtime composition
Copy `hitorro-app/pom.xml` to `hitorro-app-lite/pom.xml` and include only the modules you need.

## Alternative Run Configurations

If you need to run a different main class, you can:
1. Edit the run configuration
2. Change the **Main class** to your desired class
3. Keep **Module** as `hitorro-app`
4. The classpath will still include all modules

Or create additional runner modules with different dependency sets.

## Troubleshooting

**Problem**: IntelliJ doesn't recognize the modules  
**Solution**: File → Invalidate Caches → Invalidate and Restart

**Problem**: Class not found at runtime  
**Solution**: Ensure you selected `hitorro-app` as the module, not `hitorro-root`

**Problem**: Want to add/remove modules from runtime classpath  
**Solution**: Edit `hitorro-app/pom.xml` and add/remove dependencies as needed

**Problem**: Compilation errors  
**Solution**: Run `mvn clean install` from the terminal to see detailed error messages
