# Hitorro Project

A comprehensive multi-module Maven project for natural language processing, text analysis, and data management.

## Project Structure

This is a Maven multi-module project with the following modules:

### Core Modules
- **hitorro-util** - Utility library with common functionality
- **hitorro-base** - Base components including NLP tools and core processing
- **hitorro-unittime** - Time and temporal processing utilities

### Text Processing
- **hitorro-text-core** - Core text processing functionality
- **hitorro-text-persistence** - Text data persistence layer
- **hitorro-analysis** - Advanced text analysis and NLP components

### Data Management
- **hitorro-basedms** - Base data management system
- **hitorro-dedupe** - Deduplication utilities
- **hitorro-objretrieval** - Object retrieval system
- **hitorro-dataaquisition** - Data acquisition components
- **hitorro-jsonsql** - JSON and SQL utilities

### Feature Processing
- **hitorro-features** - Feature extraction and processing
- **hitorro-conversation** - Conversation processing
- **hitorro-logdigest** - Log processing and analysis

### UI Components
- **hitorro-baseui** - Base UI components

### Testing
- **hitorro-test** - Integration tests and test utilities

## Building the Project

### Prerequisites
- Java 19 or higher
- Maven 3.6+

### Build All Modules

```bash
# Build all modules
mvn clean install

# Build without tests
mvn clean install -DskipTests

# Build specific module
cd hitorro-util
mvn clean install
```

### Run Tests

```bash
# Run all tests
mvn test

# Run tests for specific module
cd hitorro-base
mvn test
```

### Validate Project Structure

```bash
# Validate all POMs
mvn validate

# Show dependency tree
mvn dependency:tree
```

## Module Dependencies

The modules have the following dependency hierarchy (simplified):

```
hitorro-util (base utility)
  └── hitorro-base
       └── hitorro-text-core
            ├── hitorro-analysis
            ├── hitorro-text-persistence
            └── hitorro-objretrieval
                 └── hitorro-basedms
```

## Parent POM Features

The parent POM (`pom.xml`) provides:

- **Centralized dependency management** - Common library versions defined in one place
- **Plugin management** - Standardized Maven plugin configurations
- **Common properties** - Shared build properties across all modules
- **Version management** - Single version (3.0.0) for all Hitorro modules

## Technology Stack

- **Java 19**
- **Maven** for build management
- **JUnit 5** for testing
- **Mockito** for mocking
- **AssertJ** for fluent assertions
- **Jackson** for JSON processing
- **Jetty** for web server
- **Hadoop** for distributed processing
- **OpenNLP** for NLP tasks
- **Lucene** for text analysis

## Development

### Adding a New Module

1. Create a new directory with the module name
2. Add the module to the `<modules>` section in the parent `pom.xml`
3. Create a `pom.xml` in the new module directory
4. Add any inter-module dependencies as needed

### Updating Dependencies

Common dependency versions are managed in the parent POM's `<dependencyManagement>` section. To update a dependency version:

1. Update the version property in the parent POM
2. The change will cascade to all modules using that dependency

## License

See individual module LICENSE files for details.

## Version

Current version: **3.0.0**
