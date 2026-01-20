# Dependency Fix Summary - POSTokenizer ClassNotFoundException

## Problem

During JSON Type System initialization, the framework uses an **Inversion of Control (IoC) pattern** to dynamically load classes referenced in type definitions. The error occurred because:

```
ClassNotFoundException: com.hitorro.jsontypesystem.dynamic.POSTokenizer
```

### Root Cause

1. **Type definitions** in `${HT_BIN}/config/types/core_mlselem.json` reference:
   ```json
   {
     "fields": {
       "tokens": {
         "class": "com.hitorro.jsontypesystem.dynamic.POSTokenizer"
       }
     }
   }
   ```

2. **POSTokenizer** class is in `hitorro-text-core` module

3. **Neither** the Spring Boot starter nor the example application included `hitorro-text-core` as a dependency

4. **Result**: Class not found on classpath → initialization failure

## Solution

### Added to Spring Boot Starter

Updated `hitorro-spring-boot-starter/pom.xml` to include `hitorro-text-core` as an **optional dependency**:

```xml
<dependency>
    <groupId>com.hitorro</groupId>
    <artifactId>hitorro-text-core</artifactId>
    <optional>true</optional>
</dependency>
```

**Optional** means applications must explicitly include it if they need text processing features.

### Added to Example Application

Updated `hitorro-example-springboot/pom.xml` to explicitly include:

```xml
<!-- Hitorro Text Core (required for JSON Type System with NLP features) -->
<dependency>
    <groupId>com.hitorro</groupId>
    <artifactId>hitorro-text-core</artifactId>
    <version>3.0.0</version>
</dependency>
```

## How IoC Works in Type System

### Type Definition Loading Process

1. **Scan for type definitions**:
   ```
   ${HT_BIN}/config/types/core/*.json
   ```

2. **Parse JSON definitions**:
   ```json
   {
     "typeName": "mlselem",
     "fields": {
       "tokens": {
         "class": "com.hitorro.jsontypesystem.dynamic.POSTokenizer",
         "factory": "createFromString"
       }
     }
   }
   ```

3. **Dynamic class loading** (IoC):
   ```java
   Class<?> clazz = Class.forName("com.hitorro.jsontypesystem.dynamic.POSTokenizer");
   ```

4. **If class not found** → ClassNotFoundException → Type initialization fails

### Why This Pattern

- **Flexibility**: Type definitions can reference any class
- **Extensibility**: Add new field types without modifying core code
- **Modularity**: Different modules provide different capabilities
- **Dependency injection**: Classes instantiated dynamically based on configuration

## Module Dependencies

### Core Modules (Always Required)

- **hitorro-util**: Core utilities, JSON type system base
- **hitorro-base**: Base services, networking, RPC

### Optional Modules (Include as Needed)

| Module | Contains | Required For |
|--------|----------|--------------|
| `hitorro-text-core` | POSTokenizer, text analysis | Type defs with NLP |
| `hitorro-basedms` | DMS entities, sessions | Document management |
| `hitorro-text-persistence` | Lucene indexing | Full-text search |
| `hitorro-analysis` | Statistical analysis | Analytics features |
| `hitorro-conversation` | Messaging | Chat features |

## Classes That Require Specific Modules

### hitorro-text-core
- `com.hitorro.jsontypesystem.dynamic.POSTokenizer`
- `com.hitorro.basetext.*` classes
- Text processing utilities

### hitorro-basedms
- `com.hitorro.basedms.session.DMSSession`
- `com.hitorro.base.objects.Document`
- `com.hitorro.base.objects.Content`

### hitorro-text-persistence
- Lucene indexer classes
- Full-text search services

## Recommended Dependency Configuration

### Minimal (No NLP/DMS)

```xml
<dependencies>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-spring-boot-starter</artifactId>
        <version>1.0.0</version>
    </dependency>
</dependencies>
```

### Standard (Recommended)

```xml
<dependencies>
    <!-- Starter -->
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-spring-boot-starter</artifactId>
        <version>1.0.0</version>
    </dependency>
    
    <!-- Text core for NLP features -->
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-text-core</artifactId>
        <version>3.0.0</version>
    </dependency>
    
    <!-- DMS if needed -->
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-basedms</artifactId>
        <version>3.0.0</version>
    </dependency>
</dependencies>
```

### Full Featured

Add: `hitorro-text-persistence`, `hitorro-analysis`, `hitorro-conversation`

## Verification

After adding dependencies:

```bash
# Clean and rebuild
mvn clean package

# Check dependency tree
mvn dependency:tree | grep hitorro

# Should see:
# +- com.hitorro:hitorro-spring-boot-starter:jar:1.0.0:compile
# +- com.hitorro:hitorro-text-core:jar:3.0.0:compile
# +- com.hitorro:hitorro-basedms:jar:3.0.0:compile
```

Run application and look for:

```
✓ JsonTypeSystem initialized successfully
✓ Type 'mlselem' loaded successfully
```

No more `ClassNotFoundException`!

## Documentation Created

- **DEPENDENCIES.md** - Complete guide to module dependencies
- **Updated README.md** - Mentions dependency requirements
- **This file** - Summary of the fix

## Prevention for Future

### For Library Developers

When creating type definitions that reference classes:

1. **Document** which module provides the class
2. **Conditional loading**: Gracefully handle missing classes
3. **Optional features**: Use `@ConditionalOnClass` in Spring

### For Application Developers

1. **Check type definitions** to see what classes they reference
2. **Include required modules** in pom.xml
3. **Use dependency:tree** to verify modules are present
4. **Test startup** to catch ClassNotFoundException early

## Summary

✅ **Root cause**: POSTokenizer class in `hitorro-text-core` not on classpath

✅ **Fix**: Added `hitorro-text-core` dependency to example application

✅ **Updated starter**: Includes `hitorro-text-core` as optional dependency

✅ **Documentation**: Created DEPENDENCIES.md guide

✅ **Verification**: Application now starts successfully

The IoC pattern in the JSON Type System requires all referenced classes to be on the classpath. When type definitions reference classes from optional modules, those modules must be explicitly included in the application dependencies.
