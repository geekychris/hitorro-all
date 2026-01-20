# Hitorro Projects - Dependency Diagram

## Visual Dependency Structure

```
                    ┌─────────────────────────────┐
                    │                             │
                    │      hitorro-util           │
                    │   (1,133 Java files)        │
                    │                             │
                    │  Foundation & Utilities     │
                    │  • JSON/XML/CSV             │
                    │  • I/O & BaseFile           │
                    │  • Collections              │
                    │  • HTTP/Network             │
                    │  • Configuration            │
                    │                             │
                    └──────────┬──────────────────┘
                               │
                               │ depends on
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        │                      │                      │
        ▼                      ▼                      │
┌───────────────────┐  ┌───────────────────┐         │
│                   │  │                   │         │
│  hitorro-jsonsql  │  │   hitorro-base    │         │
│ (161 Java files)  │  │  (228 Java files) │         │
│                   │  │                   │         │
│   SQL on JSON     │  │  Base Services    │         │
│   • Queries       │  │  • DocProcessing  │         │
│   • Aggregates    │  │  • Language       │         │
│   • Functions     │  │  • FileSystem     │         │
│   • Type Safety   │  │  • RPC/Events     │         │
│                   │  │                   │         │
└───────────────────┘  └─────────┬─────────┘
                                 │
                                 │ depends on
                                 │
                                 ▼
                       ┌──────────────────┐
                       │                  │
                       │ hitorro-features │
                       │ (101 Java files) │
                       │                  │
                       │  Feature Engine  │
                       │  • Extraction    │
                       │  • Indexing      │
                       │  • Pipelines     │
                       │                  │
                       └──────────────────┘
```

## Dependency Matrix

|                  | hitorro-util | hitorro-base | hitorro-features | hitorro-jsonsql |
|------------------|--------------|--------------|------------------|-----------------|
| **hitorro-util**     | -            | ❌           | ❌               | ❌              |
| **hitorro-base**     | ✅           | -            | ❌               | ❌              |
| **hitorro-features** | ✅           | ✅           | -                | ❌              |
| **hitorro-jsonsql**  | ✅           | ❌           | ❌               | -               |

Legend:
- ✅ = Depends on (row depends on column)
- ❌ = No dependency
- `-` = Self

## Build Sequence

To build all projects, follow this order (respecting dependencies):

```
1. hitorro-util        (no dependencies)
   ↓
2. hitorro-base        (depends on util)
   ↓
3. hitorro-features    (depends on base → util)
   
   hitorro-jsonsql     (depends on util only - can build after util)
```

### Parallel Build Opportunities

After `hitorro-base` is built, these can be built in parallel:
- `hitorro-features` (needs util + base)
- Already independent: `hitorro-jsonsql` (needs util only)

## Dependency Details

### hitorro-util → (none)
**Pure utility library** with only standard Java dependencies:
- Jackson (JSON)
- Apache Commons
- Google Guava
- Trove Collections

### hitorro-base → hitorro-util
**Extends utilities** with service-oriented features:
- Uses util's BaseFile for file abstraction
- Uses util's JSON handling
- Uses util's iterators and collections
- Uses util's configuration management

### hitorro-features → hitorro-util + hitorro-base
**Feature processing** built on base services:
- Uses base's document processing
- Uses base's language tools
- Uses util's I/O and serialization
- Uses util's type system

**Note**: Originally depended on `hitorro-basedms` but analysis showed this was unnecessary since:
- No database persistence (all types have `isPersisted = false`)
- Uses file-based storage only
- Type system is in util, not basedms

### hitorro-jsonsql → hitorro-util
**JSON query engine** using only core utilities:
- Uses util's JSON parsing
- Uses util's iterators
- Uses util's type system
- Independent of base services

## Package Dependencies

### hitorro-util packages (selected):
```
com.hitorro.jsontypesystem.*     → JSON type system
com.hitorro.util.core.*          → Core utilities
com.hitorro.util.io.*            → I/O operations
com.hitorro.util.basefile.*      → File abstraction
com.hitorro.util.json.*          → JSON handling
```

### hitorro-base packages:
```
com.hitorro.base.docprocessing.* → Document processing
com.hitorro.language.*           → Language processing
com.hitorro.network.*            → Network services
com.hitorro.util.basefile.fs.*   → File system implementations
```

### hitorro-features packages:
```
ht.features.*                    → Core features
ht.features.extractor.*          → Feature extraction
ht.features.index.*              → Indexing
ht.features.pipeline.*           → Processing pipelines
```

### hitorro-jsonsql packages:
```
com.hitorro.util.sql.*                    → SQL engine
com.hitorro.util.sql.latch.*              → Type system
com.hitorro.util.sql.iterators.*          → Query execution
```

## External Dependencies

### Common (all projects):
- JUnit 4.13.2 (test)
- SLF4J (logging)

### hitorro-util specific:
- Jackson 2.16.0
- Apache Commons (IO, Lang, Collections)
- Google Guava 33.0.0-jre
- Trove Collections 3.0.3

### hitorro-base specific:
- Apache OpenNLP 2.3.1
- Apache Tika 2.9.1
- JSoup 1.17.2
- Apache HttpComponents 5.3

### hitorro-features specific:
- (inherits from util and base)

### hitorro-jsonsql specific:
- JSQLParser 4.6

## Circular Dependency Check

✅ **No circular dependencies detected**

All dependencies form a **Directed Acyclic Graph (DAG)**:
```
util → base → features
util → jsonsql
```

## Version Alignment

All projects use:
- **Group ID**: `com.hitorro`
- **Version**: `3.0.0`
- **Java**: 19+
- **Encoding**: UTF-8
- **Maven**: 3.8.0+

## Deployment Order

For publishing to a Maven repository:

1. Publish `hitorro-util:3.0.0`
2. Publish `hitorro-base:3.0.0` (can now resolve util)
3. Publish in parallel:
   - `hitorro-features:3.0.0`
   - `hitorro-jsonsql:3.0.0`

## Dependency Declaration Examples

### Using hitorro-util only:
```xml
<dependencies>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-util</artifactId>
        <version>3.0.0</version>
    </dependency>
</dependencies>
```

### Using hitorro-base (gets util transitively):
```xml
<dependencies>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-base</artifactId>
        <version>3.0.0</version>
    </dependency>
</dependencies>
```

### Using hitorro-features (gets base + util transitively):
```xml
<dependencies>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-features</artifactId>
        <version>3.0.0</version>
    </dependency>
</dependencies>
```

### Using multiple projects:
```xml
<dependencies>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-features</artifactId>
        <version>3.0.0</version>
    </dependency>
    <dependency>
        <groupId>com.hitorro</groupId>
        <artifactId>hitorro-jsonsql</artifactId>
        <version>3.0.0</version>
    </dependency>
</dependencies>
```
