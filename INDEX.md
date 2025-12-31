# Hitorro Projects - Complete Index

This directory contains all extracted projects from the Hitorro monorepo.

## 📁 Directory Structure

```
/Users/chris/hitorro/
├── hitorro/                      # Original monorepo (preserved)
├── hitorro-util/                 # ✅ Extracted utilities
├── hitorro-base/                 # ✅ Extracted base services  
├── hitorro-features/             # ✅ Extracted feature engine
├── hitorro-jsonsql/              # ✅ Extracted JSON SQL
├── EXTRACTION_OVERVIEW.md        # 📖 Complete overview (START HERE)
├── DEPENDENCY_DIAGRAM.md         # 📊 Visual dependency structure
├── INDEX.md                      # 📑 This file
└── build-all.sh                  # 🔧 Master build script
```

## 📖 Documentation Files

### Master Documentation (this directory)

| File | Description |
|------|-------------|
| **EXTRACTION_OVERVIEW.md** | ⭐ **START HERE** - Complete overview of all projects |
| **DEPENDENCY_DIAGRAM.md** | Visual dependency structure and build order |
| **INDEX.md** | This file - navigation guide |
| **build-all.sh** | Master script to build all projects in order |

### Per-Project Documentation

Each project directory contains:

| File | Purpose |
|------|---------|
| `README.md` | Project overview, architecture, and usage examples |
| `QUICKSTART.md` | Step-by-step build and setup instructions |
| `EXTRACTION_SUMMARY.md` | Extraction statistics and details |
| `build.sh` | Project-specific build script |
| `.gitignore` | Git ignore rules |
| `pom.xml` | Maven build configuration |

## 🚀 Quick Start

### Build Everything

```bash
cd /Users/chris/hitorro
./build-all.sh
```

### Build Individual Projects

```bash
# 1. Foundation (no dependencies)
cd /Users/chris/hitorro/hitorro-util
./build.sh

# 2. Base Services (depends on util)
cd /Users/chris/hitorro/hitorro-base
./build.sh

# 3. Features (depends on base)
cd /Users/chris/hitorro/hitorro-features
./build.sh

# 4. JSON SQL (depends on util only)
cd /Users/chris/hitorro/hitorro-jsonsql
./build.sh
```

## 📦 Projects Summary

### 1. hitorro-util (Foundation)
- **Location**: `hitorro-util/`
- **Java Files**: 1,133
- **Dependencies**: None
- **Description**: Core utilities, JSON/XML/CSV, I/O, collections, networking

**Key Packages:**
- `com.hitorro.jsontypesystem.*` - JSON type system
- `com.hitorro.util.core.*` - Core utilities
- `com.hitorro.util.io.*` - I/O operations
- `com.hitorro.util.basefile.*` - File abstraction

**Maven Coordinates:**
```xml
<dependency>
    <groupId>com.hitorro</groupId>
    <artifactId>hitorro-util</artifactId>
    <version>3.0.0</version>
</dependency>
```

### 2. hitorro-base (Base Services)
- **Location**: `hitorro-base/`
- **Java Files**: 228
- **Dependencies**: hitorro-util
- **Description**: Document processing, language tools, networking, file systems

**Key Packages:**
- `com.hitorro.base.docprocessing.*` - Document processing
- `com.hitorro.language.*` - Language processing
- `com.hitorro.network.*` - Network services

**Maven Coordinates:**
```xml
<dependency>
    <groupId>com.hitorro</groupId>
    <artifactId>hitorro-base</artifactId>
    <version>3.0.0</version>
</dependency>
```

### 3. hitorro-features (Feature Engine)
- **Location**: `hitorro-features/`
- **Java Files**: 101
- **Dependencies**: hitorro-util, hitorro-base
- **Description**: Feature extraction, indexing, processing pipelines

**Key Packages:**
- `ht.features.*` - Core features
- `ht.features.extractor.*` - Feature extraction
- `ht.features.index.*` - Indexing
- `ht.features.pipeline.*` - Processing pipelines

**Maven Coordinates:**
```xml
<dependency>
    <groupId>com.hitorro</groupId>
    <artifactId>hitorro-features</artifactId>
    <version>3.0.0</version>
</dependency>
```

### 4. hitorro-jsonsql (JSON Query Engine)
- **Location**: `hitorro-jsonsql/`
- **Java Files**: 161
- **Dependencies**: hitorro-util
- **Description**: SQL-like query engine for JSON documents

**Key Packages:**
- `com.hitorro.util.sql.*` - SQL engine
- `com.hitorro.util.sql.latch.*` - Type system
- `com.hitorro.util.sql.iterators.*` - Query execution

**Maven Coordinates:**
```xml
<dependency>
    <groupId>com.hitorro</groupId>
    <artifactId>hitorro-jsonsql</artifactId>
    <version>3.0.0</version>
</dependency>
```

## 📊 Statistics

- **Total Projects**: 4 standalone + 1 original
- **Total Java Files**: 1,623 (extracted)
- **Total Lines**: ~150,000+ (estimated)
- **Java Version**: 19+
- **Maven Version**: 3.8.0+

## 🎯 Common Tasks

### Initialize Git for All Projects

```bash
for dir in hitorro-util hitorro-base hitorro-features hitorro-jsonsql; do
    cd /Users/chris/hitorro/$dir
    git init
    git add .
    git commit -m "Initial commit - extracted from Hitorro monorepo"
done
```

### Check Build Status

```bash
for dir in hitorro-util hitorro-base hitorro-features hitorro-jsonsql; do
    echo "=== $dir ==="
    cd /Users/chris/hitorro/$dir
    mvn --version 2>/dev/null && echo "✓ Maven available" || echo "✗ Maven not found"
    [ -f pom.xml ] && echo "✓ pom.xml present" || echo "✗ pom.xml missing"
    [ -d src/main/java ] && echo "✓ Source directory present" || echo "✗ Source missing"
    echo ""
done
```

### Clean All Projects

```bash
for dir in hitorro-util hitorro-base hitorro-features hitorro-jsonsql; do
    cd /Users/chris/hitorro/$dir
    mvn clean
done
```

### Package All Projects

```bash
cd /Users/chris/hitorro/hitorro-util && mvn package
cd /Users/chris/hitorro/hitorro-base && mvn package
cd /Users/chris/hitorro/hitorro-features && mvn package
cd /Users/chris/hitorro/hitorro-jsonsql && mvn package
```

## 🔍 Finding Information

### General Overview
→ Read `EXTRACTION_OVERVIEW.md` in this directory

### Dependency Information
→ Read `DEPENDENCY_DIAGRAM.md` in this directory

### Specific Project Details
→ Go to project directory and read its `README.md`

### Build Instructions
→ Go to project directory and read its `QUICKSTART.md`

### Extraction Details
→ Go to project directory and read its `EXTRACTION_SUMMARY.md`

## 🔗 Useful Links

### Project Directories
- [hitorro-util](hitorro-util/)
- [hitorro-base](hitorro-base/)
- [hitorro-features](hitorro-features/)
- [hitorro-jsonsql](hitorro-jsonsql/)

### Documentation
- [Complete Overview](EXTRACTION_OVERVIEW.md)
- [Dependency Diagram](DEPENDENCY_DIAGRAM.md)

### Original Monorepo
- [Original Hitorro](hitorro/)

## 💡 Tips

1. **Always build in dependency order**: util → base → features, jsonsql
2. **Check individual project documentation** for specific usage examples
3. **Use the master build script** (`build-all.sh`) for convenience
4. **Each project is independent** and can be versioned/released separately
5. **All projects use Java 19+** - ensure your JAVA_HOME is set correctly

## ⚠️ Important Notes

- All projects are **standalone** with no parent POM dependencies
- All projects use **clean Maven coordinates** (`com.hitorro` group)
- All projects are at **version 3.0.0** (starting fresh)
- Original monorepo is **preserved** in the `hitorro/` directory

## 📞 Need Help?

1. Check the project's `README.md` for usage examples
2. Check the project's `QUICKSTART.md` for build issues
3. Check `DEPENDENCY_DIAGRAM.md` for dependency questions
4. Check `EXTRACTION_OVERVIEW.md` for general questions

---

**Last Updated**: December 2024  
**Status**: ✅ All 4 projects successfully extracted and documented
