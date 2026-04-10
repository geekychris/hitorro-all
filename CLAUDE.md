# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Full build with tests
mvn clean install

# Build without tests
mvn clean install -DskipTests

# Build and deploy to local Maven repo (~/code/hitorro-maven)
./build-and-deploy.sh --clean
./build-and-deploy.sh --clean --skip-tests

# Run tests for a single module
mvn test -pl hitorro-jsontypesystem

# Run a single test class
mvn test -pl hitorro-jsontypesystem -Dtest=JVSTest

# Run a single test method
mvn test -pl hitorro-jsontypesystem -Dtest=JVSTest#shouldCreateEmptyJvs

# Version management
./bump-patch-version.sh   # 3.0.0 → 3.0.1
./bump-minor-version.sh   # 3.0.0 → 3.1.0
./bump-major-version.sh   # 3.0.0 → 4.0.0
./set-version.sh 3.2.5    # explicit version
```

## Project Overview

HiTorro is a modular Java 21 framework (Maven multi-module, currently v3.0.1) for building type-aware JSON processing systems with NLP capabilities. It can operate standalone or integrate with Spring Boot 3.2 via optional auto-configuration.

### Module Architecture

```
hitorro-core                    Foundation: Propaccess, JSON utils, file I/O, caching
     |
hitorro-jsontypesystem          JVS, type definitions, projections, NLP, data mapping
     |
hitorro-util                    Application infrastructure: commands, networking, scheduling
     |
hitorro-base                    Core abstractions: document processing, XML-RPC, PDFBox
     |
Domain modules                  text-core, text-persistence, basedms, index, kvstore,
                                features, unittime, jsonsql, objretrieval, dedupe,
                                analysis, logdigest, dataaquisition, conversation, baseui
     |
hitorro-test                    Test utilities (TestPlus interface)
hitorro-app                     Application entry point (CommandLine)
```

### Module Summary

| Module | Purpose |
|--------|---------|
| **hitorro-core** | Foundation utilities: Propaccess path navigation, JSON processing (Jackson), file I/O (local/HDFS/S3), caching, iteration framework, HTTP clients |
| **hitorro-jsontypesystem** | JSON Type System: JVS documents, Type/Field/Group definitions, projection executors, Groovy data mappers, JSON Schema support, NLP (OpenNLP, Snowball stemming, WordNet), classifiers |
| **hitorro-util** | Application infrastructure: command framework, state machines, ZooKeeper, Redis, mail, scheduling, telnet/SSH servers, service counters |
| **hitorro-base** | Core abstractions: document processing pipelines, type management, XML-RPC networking, PDFBox |
| **hitorro-index** | Lucene integration: fielded search, faceting, multi-language tokenization, streaming NDJson |
| **hitorro-kvstore** | RocksDB key-value store |
| **hitorro-text-core** | Text processing: NER filters, sentence enhancement, Lucene analyzers |
| **hitorro-text-persistence** | Full-text indexing and search persistence |
| **hitorro-basedms** | Document Management System with Hibernate persistence |
| **hitorro-objretrieval** | Solr-based object retrieval and search |
| **hitorro-features** | Feature extraction and management |
| **hitorro-analysis** | CKY parsing, sentiment analysis, term vectors |
| **hitorro-spring-boot** | Spring Boot auto-configuration and starter |

### Spring Boot Integration (separate modules)

- `hitorro-spring-boot/` contains `hitorro-spring-boot-autoconfigure` and `hitorro-spring-boot-starter`
- Core modules remain Spring-agnostic; Spring Boot modules bridge via auto-configuration
- `hitorro-example-springboot/` is a full demo application
- `hitorro-jvs-example-springboot/` demonstrates the type system + NLP as a standalone Spring Boot app

## Architecture Notes

- **JSON Type System (JVS)**: Central to the project. Type definitions live in `config/types/*.json`. Schemas in `config/schemas/*.schema.json`. JVS is the universal document wrapper used throughout the system.
- **Propaccess**: Dot-notation path navigation for JSON (`id.did`, `title.mls[0].text`). Defined in hitorro-core, used everywhere.
- **Projections**: Three-phase execution model (index, enrich, remove) for transforming typed documents. Defined in `jsontypesystem/executors/`.
- **Data Mapping**: Groovy DSL for transforming documents between types. Scripts in `config/transforms/`, generators in `config/generators/`.
- **ServiceContext/ServiceContextManager**: Custom dependency injection used in standalone mode (non-Spring).
- **Configuration-driven**: Type definitions, Groovy transform scripts, CSV generators, service implementation mappings (`config/implementations.json`), and `config/generalconfig.json`.
- **Module independence**: Each module can be a separate git repo. Use `./checkout-modules.sh` to clone them, `./update-modules.sh` to sync.

## Testing

- JUnit 5 (Jupiter) with Mockito and AssertJ
- Custom `TestPlus` interface (`com.hitorro.util.testframework`) provides test helper methods — lives in hitorro-core
- Surefire picks up `*Test.java` and `*Tests.java`
- `HT_HOME` environment variable is set during test execution via Surefire config
- Some integration tests are excluded from the default Surefire run
- Type system tests that need `config/` directory require `HT_HOME` to be set

## Key Conventions

- GroupId: `com.hitorro`
- Internal module dependency version: `${hitorro.version}` property (currently 3.0.0), distinct from root POM version (3.0.1)
- Artifacts deploy to `~/code/hitorro-maven` (a file-based Maven repo pushed to GitHub)
- Runtime config directory: `hitorro.runtime.config.dir` defaults to `../config` relative to module
