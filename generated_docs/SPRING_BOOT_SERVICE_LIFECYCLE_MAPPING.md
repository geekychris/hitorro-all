# Spring Boot Service Lifecycle Mapping

## Overview

This document explains how Hitorro's complete service lifecycle (as implemented in `BaseCommandLine`) has been mapped to Spring Boot's application lifecycle.

## The Complete Service Lifecycle (BaseCommandLine Pattern)

When Hitorro runs in traditional mode (e.g., command-line tools), the service lifecycle follows this exact pattern from `BaseCommandLine.executeCommand()`:

```java
// PHASE 1: Add Module and Dependencies
if (sc.addModule(command)) {
    
    // PHASE 2: Validate Configuration Keys
    String error = ServiceContext.validateConfigKeys();
    if (!StringUtil.nullOrEmptyOrBlankString(error)) {
        Console.eprintln("Unable to validate services, got error %s", error);
        System.exit(-1);
    }
    
    // PHASE 3: Initialize Services (runs all startup phases)
    error = sc.init();
    if (!StringUtil.nullOrEmptyString(error)) {
        Console.eprintln("Unable to initialize services, got error %s", error);
        Env.exitSystem("Exiting", -1);
    }
    
    // PHASE 4: Run Service (if Runnable)
    ServiceWrapper s = sc.getInitializedServiceWrapper(clazz);
    s.runIfRunnable();
    
    // PHASE 5: Shutdown
    ServiceContext.getSC().deInit();
}
```

### Service Init Phases (Phase 3 Detail)

When `serviceContext.init()` is called, it executes these startup steps in order:

1. **RegisterHooks** - Services register their pre/post hooks
2. **RegisterInterfaces** - Services register interfaces for cross-service communication
3. **InitWithUpgrade** - Services initialize with schema upgrade support
4. **InitUIDirs** - UI directories are created/validated
5. **InitDBEvents** - Database initialization events run (CSV imports, etc.)
6. **Start** - Services are started

## Spring Boot Lifecycle Mapping

### Current Implementation (ServiceContextManager)

```java
@Override
public void afterPropertiesSet() throws Exception {
    // PHASE 0: Initialize JVSProperties
    initializeHitorroProperties();
    
    // PHASE 1: Load Services (addModule)
    loadServicesFromConfiguration();
    
    // PHASE 2: Validate Configuration Keys ← NOW ADDED!
    String validationError = ServiceContext.validateConfigKeys();
    if (!StringUtil.nullOrEmptyOrBlankString(validationError)) {
        throw new IllegalStateException("Unable to validate: " + validationError);
    }
    
    // PHASE 3: Initialize Services (runs all 6 startup phases)
    serviceContext.setInitDb(properties.getServices().isDbInit());
    String initError = serviceContext.init();
    if (initError != null) {
        throw new IllegalStateException("Failed to initialize: " + initError);
    }
    
    // PHASE 4: runIfRunnable() - Available via methods:
    //   - runServiceIfRunnable(Class)
    //   - runServiceIfRunnable(String shortName)
    
    // PHASE 5: deInit() - Called in destroy() during Spring shutdown
}

@Override
public void destroy() throws Exception {
    serviceContext.deInit();  // Clean shutdown
}
```

### Complete Lifecycle Timeline

```
┌─────────────────────────────────────────────────────────────────┐
│ Spring Boot Application Startup                                 │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ HitorroEnvironmentPostProcessor                                 │
│ - Sets HT_BIN system property                                   │
│ - Sets HT_HOME system property                                  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ ServiceContextManager.afterPropertiesSet()                      │
│                                                                  │
│ Phase 0: Initialize JVSProperties                               │
│   - Load from system args                                       │
│   - Load from ${HT_BIN}/config/                                 │
│   - Load from ${HT_HOME}/config/                                │
│   - Overlay Spring Boot properties                              │
│                                                                  │
│ Phase 1: Load Services (addModule)                              │
│   - Read hitorro.services.load from application.yml             │
│   - Or read from services.{serverType} in JVSProperties         │
│   - Each service's dependencies are loaded recursively          │
│                                                                  │
│ Phase 2: Validate Configuration Keys ✓ CRITICAL                 │
│   - ServiceContext.validateConfigKeys()                         │
│   - Checks all required properties for all services             │
│   - FAILS FAST if any property validation fails                 │
│                                                                  │
│ Phase 3: Initialize Services (serviceContext.init())            │
│   3a. RegisterHooks                                             │
│   3b. RegisterInterfaces                                        │
│   3c. InitWithUpgrade                                           │
│   3d. InitUIDirs                                                │
│   3e. InitDBEvents (if dbInit=true) ← CSV imports here          │
│   3f. Start                                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ Other Spring Beans Initialize                                   │
│ - JPA/Hibernate SessionFactory                                  │
│ - Database schema created (if ddl-auto=create/update)           │
│ - REST controllers                                              │
│ - etc.                                                          │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ ApplicationReadyEvent Fired                                     │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ IntegrationEventsAutoConfiguration (OPTIONAL)                   │
│ - Only runs if hitorro.integration.run-on-startup=true          │
│ - Provides ADDITIONAL trigger for CSV imports                   │
│ - Useful when dbInit=false but you still want CSV data          │
│   IntegrationEventsContext.runInitDBEvents()                    │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ Application Running                                             │
│ - Services available via ServiceContextManager                  │
│ - Can call runServiceIfRunnable() if needed                     │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ Application Shutdown                                            │
│ ServiceContextManager.destroy()                                 │
│   - serviceContext.deInit()                                     │
│   - Services shut down in reverse order                         │
└─────────────────────────────────────────────────────────────────┘
```

## Key Differences from BaseCommandLine

| Aspect | BaseCommandLine | Spring Boot Integration |
|--------|----------------|------------------------|
| **Lifecycle Control** | Synchronous, blocking | Asynchronous, Spring-managed |
| **Phase 1: addModule** | Single command module | Multiple configured services |
| **Phase 2: validateConfigKeys** | ✓ Explicit call | ✓ **NOW INCLUDED** |
| **Phase 3: init()** | ✓ All 6 startup phases | ✓ Same 6 phases |
| **Phase 4: runIfRunnable** | ✓ Always called | Available via methods |
| **Phase 5: deInit** | ✓ Always called | ✓ In destroy() |
| **Error Handling** | System.exit(-1) | Throws exception, prevents startup |
| **Integration Events** | Runs if dbInit=true | Can run via ApplicationReadyEvent |

## Service Configuration

### Option 1: Explicit Service List

```yaml
hitorro:
  services:
    enabled: true
    db-init: false  # Set true to run InitDBEvents phase
    load:
      - com.hitorro.base.service.BasicService
      - com.hitorro.basedms.db.HibernateService
      - com.hitorro.basedms.BaseDMSService
```

### Option 2: HTServer Pattern

```yaml
hitorro:
  services:
    enabled: true
    server-type: webapp  # Reads services.webapp from JVSProperties
```

Then in your JVSProperties config:
```json
{
  "services": {
    "webapp": "com.hitorro.util.startupframework.HTServer"
  }
}
```

## Using the ServiceContextManager

### Accessing Services

```java
@Autowired
private ServiceContextManager serviceContextManager;

// Get service by class
HibernateService hibernateService = 
    serviceContextManager.getService(HibernateService.class);

// Get service by short name
Object basicService = serviceContextManager.getService("basic");

// Check if service is initialized
boolean isInit = serviceContextManager.isServiceInitialized(HibernateService.class);
```

### Running Services (Phase 4)

```java
// If a service implements Runnable and needs to be executed:
serviceContextManager.runServiceIfRunnable(MyRunnableService.class);

// Or by short name:
serviceContextManager.runServiceIfRunnable("myservice");
```

### Manual Validation

```java
// Re-validate configuration at runtime
String errors = serviceContextManager.validateConfiguration();
if (!errors.isEmpty()) {
    logger.error("Configuration validation failed: {}", errors);
}
```

## Integration Events (InitDBEvents Phase)

### When InitDBEvents Runs

The **InitDBEvents** phase (CSV imports, data loading) can run in two ways:

#### 1. During serviceContext.init() (Traditional)

Set `dbInit=true`:
```yaml
hitorro:
  services:
    db-init: true  # InitDBEvents runs during Phase 3
```

This follows the exact BaseCommandLine pattern.

#### 2. After ApplicationReady (Spring Boot Pattern)

Set `run-on-startup=true`:
```yaml
hitorro:
  services:
    db-init: false  # Skip InitDBEvents during Phase 3
  integration:
    enabled: true
    run-on-startup: true  # Run InitDBEvents after Spring ready
```

This is useful when:
- Database schema is created by Spring (ddl-auto=create)
- You want to ensure Hibernate is fully initialized first
- You need all Spring beans available during import

### Manual Triggering

```java
@Autowired
private IntegrationEventsManager integrationEventsManager;

// Run all configured events
integrationEventsManager.runAllEvents();

// Run specific event
integrationEventsManager.runEvent("htcategory");
```

## Error Handling

### Configuration Validation Errors

If Phase 2 (validateConfigKeys) fails:
```
java.lang.IllegalStateException: Unable to validate service configuration: 
Error validating key hibernate.connection.url for module hibernate with error Property is required but not set
```

**Solution**: Set all required properties in JVSProperties or application.yml

### Service Initialization Errors

If Phase 3 (init) fails:
```
java.lang.IllegalStateException: Failed to initialize Hitorro ServiceContext: 
Unable to complete phase InitWithUpgrade Unable to initialize module basic with error...
```

**Solution**: Check logs for specific service that failed and its error message

## Best Practices

### 1. Configuration Validation

The Phase 2 validation is **critical**. It prevents the application from starting with invalid configuration, just like BaseCommandLine does.

✅ **Do**: Let validation fail startup in dev/test
❌ **Don't**: Catch and swallow validation exceptions

### 2. Service Loading Order

Services are loaded with their dependencies automatically:
```yaml
load:
  - com.hitorro.basedms.BaseDMSService  # Will auto-load HibernateService, BasicService, etc.
```

### 3. Integration Events Timing

For **production**:
```yaml
services:
  db-init: false
integration:
  run-on-startup: false  # Manual trigger only
```

For **development/test**:
```yaml
services:
  db-init: true  # Run during init
# OR
integration:
  run-on-startup: true  # Run after ready
```

### 4. Runnable Services

If you have services that need to execute (implement Runnable):
```java
@EventListener(ApplicationReadyEvent.class)
public void runServices() {
    serviceContextManager.runServiceIfRunnable(MyProcessorService.class);
}
```

## Summary

The Spring Boot integration now **fully implements** the BaseCommandLine service lifecycle:

✅ **Phase 1**: addModule - Service loading with dependencies  
✅ **Phase 2**: validateConfigKeys - Configuration validation (NOW ADDED)  
✅ **Phase 3**: init() - All 6 startup phases  
✅ **Phase 4**: runIfRunnable() - Available via methods  
✅ **Phase 5**: deInit() - Clean shutdown  

The key improvements:
1. **Explicit validation step** prevents startup with bad config
2. **Phase control** via properties (dbInit flag)
3. **Runnable services** can be executed programmatically
4. **Integration events** can run during init OR after ApplicationReady
5. **Same error handling** as BaseCommandLine (fail fast)

This maintains **100% compatibility** with the traditional Hitorro service lifecycle while adapting it to Spring Boot's asynchronous initialization model.
