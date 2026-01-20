# Maven Commands Reference

Quick reference for common Maven commands in this multi-module project.

## Building

```bash
# Clean and build all modules
mvn clean install

# Build without running tests (faster)
mvn clean install -DskipTests

# Build only (without cleaning)
mvn install

# Build with verbose output
mvn clean install -X

# Build in parallel (uses multiple threads)
mvn clean install -T 4

# Build specific module and its dependencies
mvn clean install -pl hitorro-base -am

# Build specific module only (no dependencies)
mvn clean install -pl hitorro-base
```

## Testing

```bash
# Run all tests in all modules
mvn test

# Run tests in specific module
mvn test -pl hitorro-base

# Run a specific test class
mvn test -Dtest=MyTestClass

# Run a specific test method
mvn test -Dtest=MyTestClass#testMethod

# Skip tests
mvn install -DskipTests

# Run tests with code coverage
mvn clean test jacoco:report
```

## Dependencies

```bash
# Show dependency tree for all modules
mvn dependency:tree

# Show dependency tree for specific module
mvn dependency:tree -pl hitorro-base

# Analyze dependencies
mvn dependency:analyze

# Show effective POM (with parent inheritance resolved)
mvn help:effective-pom

# Download sources for dependencies
mvn dependency:sources

# Show outdated dependencies
mvn versions:display-dependency-updates
```

## Validation

```bash
# Validate project structure
mvn validate

# Check for duplicate dependencies
mvn dependency:analyze-duplicate

# Verify checksums
mvn verify
```

## Cleaning

```bash
# Clean all target directories
mvn clean

# Clean specific module
mvn clean -pl hitorro-base

# Deep clean (remove all generated files)
mvn clean install -U
```

## Module Operations

```bash
# Build modules in specific order
mvn clean install --projects hitorro-util,hitorro-base

# Resume build from specific module (after failure)
mvn install -rf :hitorro-analysis

# Build only changed modules
mvn install --also-make-dependents

# List all modules
mvn help:evaluate -Dexpression=project.modules -q -DforceStdout
```

## Reactor Build Order

```bash
# Show build order without executing
mvn validate

# The reactor will automatically determine build order based on dependencies
# Output shows the order: util -> base -> text-core -> analysis, etc.
```

## Version Management

```bash
# Show current version
mvn help:evaluate -Dexpression=project.version -q -DforceStdout

# Update all module versions
mvn versions:set -DnewVersion=3.1.0

# Commit version change
mvn versions:commit

# Revert version change
mvn versions:revert
```

## Package & Deploy

```bash
# Package all modules (creates JARs)
mvn package

# Package with assembly (includes dependencies)
mvn package assembly:single

# Install to local repository
mvn install

# Deploy to remote repository (requires configuration)
mvn deploy
```

## Useful Combinations

```bash
# Quick rebuild without tests
mvn clean install -DskipTests -T 4

# Build and show what changed
mvn clean install -pl '!hitorro-test' -am

# Offline build (use cached dependencies)
mvn clean install -o

# Update snapshots
mvn clean install -U

# Generate documentation
mvn clean install site
```

## Troubleshooting

```bash
# Debug build issues
mvn clean install -X

# Show plugin help
mvn help:describe -Dplugin=compiler

# Show effective settings
mvn help:effective-settings

# Purge local repository cache
mvn dependency:purge-local-repository

# Force re-download of dependencies
mvn clean install -U
```

## Common Flags

- `-am, --also-make` - Build dependencies of specified modules
- `-amd, --also-make-dependents` - Build modules that depend on specified modules
- `-pl, --projects` - Specify module(s) to build
- `-rf, --resume-from` - Resume build from specified module
- `-T` - Build in parallel (e.g., `-T 4` for 4 threads)
- `-U, --update-snapshots` - Force update of snapshots
- `-X, --debug` - Debug output
- `-e, --errors` - Show error stack traces
- `-q, --quiet` - Quiet output
- `-o, --offline` - Work offline
- `-N, --non-recursive` - Don't recurse into sub-modules
- `-DskipTests` - Skip test execution
- `-Dmaven.test.skip=true` - Skip test compilation and execution

## Examples

### Build only hitorro-base and its dependencies
```bash
mvn clean install -pl hitorro-base -am
```

### Build all modules that depend on hitorro-util
```bash
mvn clean install -pl hitorro-util -amd
```

### Quick test of changes in hitorro-analysis
```bash
mvn clean test -pl hitorro-analysis
```

### Full rebuild in parallel
```bash
mvn clean install -T 4
```
