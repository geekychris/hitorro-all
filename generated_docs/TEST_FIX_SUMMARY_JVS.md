# JVS Integration Test Fix Summary

## Problem

The `HitorroJVSIntegrationTest` was failing with multiple cascading errors:

1. **Logging Conflict**: Multiple SLF4J bindings (Logback from Spring Boot vs reload4j from Hitorro modules)
2. **Missing ht_data Property**: `Iso639Table.getInstance()` returning null because language table couldn't be loaded
3. **Uninitialized JVSProperties**: FileProperty resolution failing because JVSProperties not initialized with system args

## Root Causes

### 1. SLF4J Binding Conflict

**Error**:
```
LoggerFactory is not a Logback LoggerContext but Logback is on the classpath.
Either remove Logback or the competing implementation 
(class org.slf4j.reload4j.Reload4jLoggerFactory)
```

**Cause**: Hitorro modules (`hitorro-basedms`, `hitorro-text-core`) were pulling in:
- `log4j:log4j:1.2.17` (Log4j 1.x)
- `slf4j-reload4j:2.0.11` (SLF4J binding for Log4j 1.2)

Spring Boot already includes:
- `logback-classic` (another SLF4J binding)

Multiple SLF4J bindings cause Spring Boot to fail during initialization.

### 2. Missing ht_data System Property

**Error**:
```
NullPointerException: Cannot invoke "com.hitorro.language.Iso639Table.getRow(String)" 
because the return value of "com.hitorro.language.Iso639Table.getInstance()" is null
```

**Cause**: 
- `Iso639Table` needs to read `${ht_data}/iso639.psv` 
- `ht_data` property was not being set as a system property
- `FileProperty` resolver couldn't resolve `${ht_data}` variable

### 3. JVSProperties Not Initialized

**Cause**:
- `FileProperty.getDefaultFile()` calls `JVSProperties.getProperties().resolveJsonVariable()`
- `JVSProperties` singleton was never initialized with system args
- Without initialization, variable resolution fails

## Solutions Applied

### Fix 1: Exclude Log4j 1.x Dependencies

**File**: `hitorro-example-springboot/pom.xml`

Added exclusions to all Hitorro dependencies:

```xml
<dependency>
    <groupId>com.hitorro</groupId>
    <artifactId>hitorro-spring-boot-starter</artifactId>
    <version>1.0.0</version>
    <exclusions>
        <exclusion>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
        </exclusion>
        <exclusion>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-reload4j</artifactId>
        </exclusion>
        <exclusion>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-log4j12</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

Applied to:
- `hitorro-spring-boot-starter`
- `hitorro-basedms`
- `hitorro-text-core`

**Result**: Spring Boot now uses Logback exclusively, no binding conflicts.

### Fix 2: Configure ht_data System Property

**File**: `hitorro-spring-boot-autoconfigure/src/main/java/com/hitorro/spring/autoconfigure/HitorroEnvironmentPostProcessor.java`

Added `configureHtData()` method:

```java
private void configureHtData() {
    String htData = System.getProperty("ht_data");
    
    if (htData != null) {
        logger.debug("ht_data already set via system property: {}", htData);
        return;
    }
    
    // Try environment variable
    htData = System.getenv("HT_DATA");
    if (htData != null) {
        System.setProperty("ht_data", htData);
        logger.info("ht_data set from environment variable: {}", htData);
        return;
    }
    
    // Derive from HT_BIN (standard Hitorro convention: ${HT_BIN}/data)
    String htBin = System.getProperty("HT_BIN");
    if (htBin != null) {
        htData = htBin + "/data";
        System.setProperty("ht_data", htData);
        logger.info("ht_data derived from HT_BIN: {}", htData);
        return;
    }
    
    logger.warn("ht_data not configured (derived value unavailable, HT_BIN not set)");
}
```

Called during environment post-processing (after HT_BIN is set).

**Result**: `ht_data` now resolves to `/Users/chris/hitorro/data`, allowing `Iso639Table` to find `iso639.psv`.

### Fix 3: Initialize JVSProperties with System Args

**File**: `hitorro-spring-boot-autoconfigure/src/main/java/com/hitorro/spring/autoconfigure/jvs/JsonTypeSystemManager.java`

Added `initializeJVSProperties()` method called BEFORE any type loading:

```java
private void initializeJVSProperties() {
    logger.debug("Initializing JVSProperties with system args...");
    
    // Create a JVS document with system args
    JVS props = new JVS();
    
    // Get system args from Env (includes HT_BIN, HT_HOME, ht_data, etc.)
    Map<String, String> systemArgs = Env.getSystemArgs();
    
    logger.debug("System args:");
    for (Map.Entry<String, String> entry : systemArgs.entrySet()) {
        logger.debug("  {} = {}", entry.getKey(), entry.getValue());
        props.set(entry.getKey(), entry.getValue());
    }
    
    // Set as default properties (used by FileProperty for variable resolution)
    JVSProperties.setDefaultProperties(props, false);
    
    logger.info("✓ JVSProperties initialized with {} system args", systemArgs.size());
}
```

**Result**: 
- `JVSProperties` now has all system properties
- `FileProperty` can resolve variables like `${ht_data}`, `${HT_BIN}`, `${HT_HOME}`
- Language tables, type definitions, and other file-based resources load correctly

### Fix 4: Update Test Configuration

**File**: `hitorro-example-springboot/src/test/resources/application-test.yml`

Updated to use proper configuration variables:

```yaml
hitorro:
  # Core Hitorro paths
  ht-bin: ${HT_BIN:/Users/chris/hitorro}
  ht-home: ${HT_HOME:/Users/chris/hthome}
  
  jvs:
    enabled: true
    nlp-enabled: false
    type-definitions-path: ${HT_BIN:/Users/chris/hitorro}
```

**Result**: Test configuration properly sets HT_BIN and HT_HOME, which are picked up by the environment post-processor.

## Test Results

### Before Fixes
```
[ERROR] Tests run: 30, Failures: 0, Errors: 30, Skipped: 0
[ERROR] ApplicationContext failure - LoggerFactory conflict
[ERROR] ExceptionInInitializerError - Iso639Table.getInstance() returns null
```

### After Fixes
```
[INFO] Tests run: 30, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

## Files Modified

1. **hitorro-example-springboot/pom.xml**
   - Added exclusions for Log4j 1.x dependencies

2. **hitorro-spring-boot/pom.xml**
   - Added `hitorro-text-core` to dependency management

3. **hitorro-spring-boot-autoconfigure/.../HitorroEnvironmentPostProcessor.java**
   - Added `configureHtData()` method

4. **hitorro-spring-boot-autoconfigure/.../JsonTypeSystemManager.java**
   - Added `initializeJVSProperties()` method
   - Called before any type system initialization

5. **hitorro-example-springboot/src/test/resources/application-test.yml**
   - Updated to use proper configuration properties

## Key Takeaways

### 1. **Logging in Spring Boot Applications**
- Spring Boot prefers Logback
- Exclude legacy Log4j 1.x when integrating with modules that use it
- Only one SLF4J binding can be active

### 2. **Hitorro System Properties**
- `HT_BIN`: Project root (e.g., `/Users/chris/hitorro`)
- `HT_HOME`: Home directory (e.g., `/Users/chris/hthome`)
- `ht_data`: Data directory - **MUST** be set to `${HT_BIN}/data`

### 3. **Initialization Order Matters**
```
1. EnvironmentPostProcessor (set HT_BIN, HT_HOME, ht_data)
   ↓
2. JsonTypeSystemManager.initializeJVSProperties()
   ↓
3. Load type definitions, language tables, etc.
```

### 4. **JVSProperties Requirement**
- **Must** be initialized before any `FileProperty` is used
- Contains system args for variable resolution
- Critical for: type loading, language tables, NLP models, etc.

## Verification

All 30 tests now pass including:
- ✅ Spring Boot integration tests
- ✅ JVS construction and parsing
- ✅ Property access tests
- ✅ JSON operations
- ✅ Edge cases
- ✅ Real-world scenarios
- ✅ NLP-aware features (field access validation)

The application correctly:
- Initializes Spring context without logging conflicts
- Loads language tables from disk
- Resolves FileProperty variables
- Provides helpful error messages when type definitions are missing

## Next Steps

To enable full NLP functionality with type definitions and language processing:

1. **Ensure type definitions exist**: `${HT_BIN}/config/types/core/*.json`
2. **Set up data directory**: `${ht_data}/iso639.psv` and stemmers
3. **Enable NLP**: `hitorro.jvs.nlp-enabled: true` in application.yml
4. **Configure WordNet**: Place data in `${HT_HOME}/data/wordnet/`

The test framework gracefully handles missing optional data files and provides clear guidance on what's needed.
