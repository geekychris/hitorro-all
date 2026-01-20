# Quick Start Guide

## Problem
You created an IntelliJ run configuration for `com.hitorro.util.cmdline.CommandLine` but selected the `hitorro-root` module, which has `<packaging>pom</packaging>` and cannot run code.

## Solution
Use the new `hitorro-app` module instead.

## IntelliJ Setup (3 Steps)

### 1. Reload Maven Project
```
Right-click pom.xml → Maven → Reload Project
```

### 2. Edit Your Run Configuration
- **Module**: Change from `hitorro-root` to **`hitorro-app`**
- **Main class**: `com.hitorro.util.cmdline.CommandLine`
- **Everything else**: Keep as is

### 3. Run
Click the Run button. ✅

## What is hitorro-app?

A new module that:
- Includes **all 16 Hitorro modules** in its classpath
- Provides a single execution context for running applications
- **Does NOT affect module independence** - they remain standalone

## Architecture Summary

```
┌──────────────┐
│ hitorro-root │  ← Aggregator (can't run code)
└──────────────┘
        │
        ├── hitorro-util      (independent)
        ├── hitorro-base      (independent)
        ├── ... 14 more ...   (all independent)
        │
        └── hitorro-app       (depends on all above)
                              ↑
                              Use this for running!
```

## Key Points

✅ **All sub-modules remain independent** - can be used separately  
✅ **hitorro-app provides unified runtime** - includes all modules  
✅ **No parent-child coupling** - modules are truly standalone  
✅ **Flexible** - edit hitorro-app dependencies to change module set  

## Runtime Dependencies

The `hitorro-app` module includes:
- All 16 Hitorro modules
- **MySQL Connector/J 8.0.33** (for JDBC/Hibernate support)

## Customization

Want different modules in your runtime? Edit `hitorro-app/pom.xml`:

```xml
<dependencies>
    <!-- Add or remove modules as needed -->
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-util</artifactId>
        <version>3.0.0</version>
    </dependency>
    <!-- ... more dependencies ... -->
    
    <!-- Runtime dependencies (drivers, etc.) -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <version>8.0.33</version>
        <scope>runtime</scope>
    </dependency>
</dependencies>
```

## See Also
- `INTELLIJ_RUN_CONFIGURATION.md` - Detailed IntelliJ setup
- `ARCHITECTURE.md` - Complete architecture explanation
