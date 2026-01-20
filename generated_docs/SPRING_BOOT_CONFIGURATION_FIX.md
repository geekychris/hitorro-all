# Spring Boot Configuration Fix - Complete Solution

## Problem Statement

The `hitorro-example-springboot` application was not initializing the JSON Type System properly because `HT_BIN` and `HT_HOME` system properties were not being configured before Spring Boot's bean initialization phase.

## Root Cause

The Hitorro framework requires `HT_BIN` and `HT_HOME` to be set as **JVM system properties** before components initialize. Spring Boot's auto-configuration creates beans very early in the startup process, but these properties were being set too late (or not at all).

## Complete Solution (3-Layer Defense)

We implemented a **defense-in-depth** approach with three layers:

### Layer 1: EnvironmentPostProcessor (Earliest - NEW)

**File**: `hitorro-spring-boot-autoconfigure/src/main/java/com/hitorro/spring/autoconfigure/HitorroEnvironmentPostProcessor.java`

**Purpose**: Runs BEFORE Spring context initialization

**How it works**:
- Registered via `META-INF/spring.factories`
- Executes during Spring Boot's environment preparation phase
- Checks system properties → environment variables → Spring config
- Sets system properties if not already configured

**Priority**:
1. JVM system property (if already set)
2. Environment variable (`export HT_BIN=...`)
3. Spring configuration (`hitorro.jvs.type-definitions-path`)

**Registration** (`META-INF/spring.factories`):
```properties
org.springframework.boot.env.EnvironmentPostProcessor=\
com.hitorro.spring.autoconfigure.HitorroEnvironmentPostProcessor
```

### Layer 2: Application Main Method

**File**: `hitorro-example-springboot/src/main/java/com/hitorro/example/HitorroExampleApplication.java`

**Purpose**: Fallback defaults BEFORE Spring starts

**How it works**:
```java
public static void main(String[] args) {
    // CRITICAL: Configure BEFORE SpringApplication.run()
    configureHitorroSystemProperties();
    
    SpringApplication.run(HitorroExampleApplication.class, args);
}

private static void configureHitorroSystemProperties() {
    // Sets defaults if not configured via other methods
    // Provides helpful warnings
    // Logs configuration for debugging
}
```

**Provides**:
- Default fallback values for development
- Early warning messages if not configured
- Confirmation logging

### Layer 3: JsonTypeSystemManager Validation

**File**: `hitorro-spring-boot-autoconfigure/.../jvs/JsonTypeSystemManager.java`

**Purpose**: Final validation and detailed error reporting

**How it works**:
- Runs during Spring bean initialization (`InitializingBean`)
- By this point, properties should already be set
- Provides detailed error messages if still missing
- Logs complete configuration for troubleshooting

**Enhanced logging**:
```
=== Initializing JsonTypeSystem ===
✓ HT_BIN already configured: /Users/chris/hitorro
✓ HT_HOME configured: /Users/chris/hthome
✓ JsonTypeSystem initialized successfully
  Type definitions path: /Users/chris/hitorro/config/types/core/
=== JsonTypeSystem initialization complete ===
```

## Configuration Sequence

The complete startup sequence:

```
1. JVM starts with -DHT_BIN=... (if provided)
   └─> Properties already set ✓

2. Application main() executes
   └─> Checks and sets defaults if needed
   └─> Logs: "HT_BIN configured: ..."

3. Spring Boot Environment Preparation
   └─> HitorroEnvironmentPostProcessor runs
   └─> Validates system properties are set
   └─> Logs: "✓ HT_BIN already set" or sets from env/config

4. Spring Context Initialization
   └─> JsonTypeSystemManager bean created
   └─> afterPropertiesSet() validates configuration
   └─> JsonTypeSystem.getMe() initializes
   └─> Logs: "✓ JsonTypeSystem initialized successfully"
```

## Files Created/Modified

### New Files in hitorro-spring-boot:
- ✅ `HitorroEnvironmentPostProcessor.java` - Early property configuration
- ✅ `META-INF/spring.factories` - Registers the post-processor

### New Files in hitorro-example-springboot:
- ✅ `run.sh` - Convenient run script with proper configuration
- ✅ `CONFIGURATION.md` - Comprehensive configuration guide
- ✅ `TROUBLESHOOTING.md` - Detailed troubleshooting guide
- ✅ `SETUP_SUMMARY.md` - Quick reference

### Modified Files:
- ✅ `HitorroExampleApplication.java` - Early property setup in main()
- ✅ `application.yml` - Added JVS configuration section
- ✅ `JsonTypeSystemManager.java` - Enhanced logging and validation
- ✅ `README.md` - Updated with configuration instructions

### IntelliJ Configuration:
- ✅ `idea/runConfigurations/HitorroExampleSpringBoot.run.xml` - Proper VM options

## Usage Examples

### Method 1: Run Script (Easiest)
```bash
cd hitorro-example-springboot
./run.sh
```

### Method 2: Environment Variables
```bash
export HT_BIN=/Users/chris/hitorro
export HT_HOME=/Users/chris/hthome
mvn spring-boot:run
```

### Method 3: JVM Arguments
```bash
java -DHT_BIN=/Users/chris/hitorro \
     -DHT_HOME=/Users/chris/hthome \
     -jar target/hitorro-example-springboot-*.jar
```

### Method 4: Spring Configuration
```yaml
# application.yml
hitorro:
  jvs:
    type-definitions-path: /Users/chris/hitorro
```

### Method 5: IntelliJ IDEA
- Select "HitorroExampleSpringBoot" run configuration
- Click Run (VM options already configured)

## Verification

### Success Indicators

Look for these messages in startup logs:

```
HT_BIN configured: /Users/chris/hitorro
HT_HOME configured: /Users/chris/hthome
=== Initializing JsonTypeSystem ===
✓ HT_BIN already configured: /Users/chris/hitorro
✓ HT_HOME configured: /Users/chris/hthome
✓ JsonTypeSystem initialized successfully
  Type definitions path: /Users/chris/hitorro/config/types/core/
=== JsonTypeSystem initialization complete ===
```

### Failure Indicators

If you see these, configuration is missing:

```
WARNING: HT_BIN not configured
╔════════════════════════════════════════════════════════════╗
║ CRITICAL: HT_BIN not configured!                          ║
╚════════════════════════════════════════════════════════════╝
```

## Why This Solution Works

### Problem with Previous Approaches:
1. ❌ Setting in `@PostConstruct` - Too late (beans already creating)
2. ❌ Setting in bean constructors - Too late (dependencies already resolving)
3. ❌ Relying on application.yml alone - Not converted to system properties

### Why This Solution Works:
1. ✅ **EnvironmentPostProcessor** - Runs in environment preparation phase
2. ✅ **main() setup** - Executes before Spring starts
3. ✅ **System properties** - Available to all components immediately
4. ✅ **Multiple fallbacks** - Graceful degradation if one layer fails
5. ✅ **Clear logging** - Easy to diagnose configuration issues

## Configuration Priority

The system checks sources in this order:

1. **JVM System Properties** (`-DHT_BIN=...`)
   - Highest priority
   - Set on command line
   - Cannot be overridden

2. **Environment Variables** (`export HT_BIN=...`)
   - Second priority
   - Set in shell or CI/CD
   - Portable across environments

3. **Spring Configuration** (`application.yml`)
   - Third priority
   - Converted to system properties by EnvironmentPostProcessor
   - Good for containerized deployments

4. **Application Defaults** (hardcoded in `main()`)
   - Last resort
   - Development-specific
   - Should be overridden in production

## Production Deployment

### Docker:
```dockerfile
ENV HT_BIN=/app/hitorro
ENV HT_HOME=/data/hitorro
```

### Kubernetes:
```yaml
env:
  - name: HT_BIN
    value: /opt/hitorro
  - name: HT_HOME
    value: /var/lib/hitorro
```

### Systemd:
```ini
[Service]
Environment="HT_BIN=/opt/hitorro"
Environment="HT_HOME=/var/lib/hitorro"
```

## Testing

Run with debug logging to see complete initialization:

```bash
java -DHT_BIN=/Users/chris/hitorro \
     -DHT_HOME=/Users/chris/hthome \
     -Dlogging.level.com.hitorro.spring.autoconfigure=DEBUG \
     -jar target/hitorro-example-springboot-*.jar
```

## Documentation

Complete documentation available in:

- **CONFIGURATION.md** - All configuration methods
- **TROUBLESHOOTING.md** - Problem diagnosis and solutions
- **SETUP_SUMMARY.md** - Quick reference
- **README.md** - Updated with quick start

## Summary

The solution ensures `HT_BIN` and `HT_HOME` are configured through a **three-layer defense**:

1. **EnvironmentPostProcessor** (NEW) - Earliest possible configuration
2. **Application main()** - Defaults before Spring starts
3. **JsonTypeSystemManager** - Validation during bean creation

This guarantees properties are available when any Hitorro component initializes, regardless of configuration method used.
