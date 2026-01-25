# Hitorro Build and Deployment Guide

## Overview

The Hitorro project is configured to deploy artifacts to a local Maven repository that is then pushed to GitHub for consumption by other projects.

### Deployment Repository

By default, artifacts are deployed to:
```
${user.home}/code/hitorro-maven
```

You can customize the deployment path by:
1. **Command line**: `mvn deploy -Dhitorro.deploy.repo.path=/custom/path`
2. **POM property**: Edit the `<hitorro.deploy.repo.path>` property in the root `pom.xml`
3. **Maven settings**: Define the property in `~/.m2/settings.xml`

### GitHub Repository

Deployed artifacts are committed and pushed to:
```
https://github.com/geekychris/hitorro-maven
```

Consumers can reference artifacts directly from GitHub without cloning the repository.

## Quick Start

### Deploy Current Version
```bash
./build-and-deploy.sh --clean --skip-tests
```

### Update Version and Deploy
```bash
# For a patch release (3.0.0 → 3.0.1)
./bump-patch-version.sh
./build-and-deploy.sh --clean

# For a minor release (3.0.0 → 3.1.0)
./bump-minor-version.sh
./build-and-deploy.sh --clean

# For a major release (3.0.0 → 4.0.0)
./bump-major-version.sh
./build-and-deploy.sh --clean
```

## Available Scripts

### Build and Deploy
**`./build-and-deploy.sh`** - Build and deploy all modules

Options:
- `-c, --clean` - Clean before building
- `-s, --skip-tests` - Skip running tests
- `-h, --help` - Show help

Examples:
```bash
# Full build with tests
./build-and-deploy.sh --clean

# Fast deployment without tests
./build-and-deploy.sh --clean --skip-tests

# Deploy without cleaning
./build-and-deploy.sh
```

### Version Management

**`./bump-major-version.sh`** - Increment major version (X.0.0)
- Example: 3.0.0 → 4.0.0

**`./bump-minor-version.sh`** - Increment minor version (x.X.0)
- Example: 3.0.0 → 3.1.0

**`./bump-patch-version.sh`** - Increment patch version (x.x.X)
- Example: 3.0.0 → 3.0.1

**`./set-version.sh <version>`** - Set a specific version
- Example: `./set-version.sh 3.2.5`

## Manual Maven Commands

You can also use Maven directly:

```bash
# Deploy to local repository
mvn clean deploy

# Deploy without tests
mvn clean deploy -DskipTests

# Install to ~/.m2/repository only (not to hitorro-maven)
mvn clean install
```

## Using Hitorro Artifacts in Other Projects

### Option 1: GitHub Repository (Recommended for external projects)

Add to your `pom.xml`:

```xml
<repositories>
    <repository>
        <id>hitorro-maven</id>
        <name>Hitorro Maven Repository</name>
        <url>https://raw.githubusercontent.com/geekychris/hitorro-maven/main</url>
    </repository>
</repositories>
```

### Option 2: Local File Repository (For local development)

Add to your `pom.xml`:

```xml
<repositories>
    <repository>
        <id>hitorro-local</id>
        <name>Hitorro Local Maven Repository</name>
        <url>file://${user.home}/code/hitorro-maven</url>
    </repository>
</repositories>

<dependencies>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-util</artifactId>
        <version>3.0.0</version>
    </dependency>
    <!-- Add other modules as needed -->
</dependencies>
```

## Project Modules

All modules share the same version number:

1. `hitorro-util` - Utility classes
2. `hitorro-base` - Base classes and interfaces
3. `hitorro-unittime` - Time unit handling
4. `hitorro-features` - Feature extraction
5. `hitorro-jsonsql` - JSON SQL support
6. `hitorro-jsonts-mongo` - JSON TypeScript MongoDB support
7. `hitorro-objretrieval` - Object retrieval
8. `hitorro-text-core` - Text processing core
9. `hitorro-text-persistence` - Text persistence
10. `hitorro-basedms` - Base DMS functionality
11. `hitorro-dedupe` - Deduplication
12. `hitorro-analysis` - Analysis tools
13. `hitorro-logdigest` - Log digest
14. `hitorro-dataaquisition` - Data acquisition
15. `hitorro-conversation` - Conversation handling
16. `hitorro-baseui` - Base UI components
17. `hitorro-test` - Testing utilities
18. `hitorro-app` - Application module
19. `hitorro-spring-boot` - Spring Boot integration
20. `hitorro-example-springboot` - Spring Boot examples

## Version Management Best Practices

1. **Patch versions** (x.x.X) - Bug fixes, no API changes
2. **Minor versions** (x.X.0) - New features, backward compatible
3. **Major versions** (X.0.0) - Breaking changes

## Workflow Example

```bash
# 1. Make changes to code
# ... edit files ...

# 2. Update version (for a new feature)
./bump-minor-version.sh

# 3. Build and deploy
./build-and-deploy.sh --clean

# 4. Commit and push to GitHub (in hitorro-maven repo)
cd ${HOME}/code/hitorro-maven
git add .
git commit -m "Release version 3.1.0

Co-Authored-By: Warp <agent@warp.dev>"
git push

# 5. Other projects can now use version 3.1.0 from GitHub
```

## Troubleshooting

### Build Failures
```bash
# Clean everything and rebuild
mvn clean
./build-and-deploy.sh --clean --skip-tests
```

### Version Conflicts
```bash
# Check current version
mvn help:evaluate -Dexpression=project.version -q -DforceStdout

# Set to specific version if needed
./set-version.sh 3.0.0
```

### Repository Issues
```bash
# Verify repository structure
ls -la /Users/chris/code/hitorro-maven/com/hitorro/

# Check if artifacts were deployed
find /Users/chris/code/hitorro-maven -name "*.jar" -type f
```
