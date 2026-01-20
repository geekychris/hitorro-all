# Spring Boot Integration Events Guide

## Overview

This guide explains how Hitorro's CSV integration events work in Spring Boot applications and how they've been properly integrated into the Spring lifecycle.

## The Problem

In traditional Hitorro applications (using `BaseCommandLine`), the service initialization follows a strict multi-phase lifecycle:

1. **RegisterHooks** - Register service hooks
2. **RegisterInterfaces** - Register service interfaces  
3. **InitWithUpgrade** - Initialize services with upgrade support
4. **InitUIDirs** - Initialize UI directories
5. **InitDBEvents** - **Run DB initialization events (CSV imports)** ← Critical phase
6. **Start** - Start services

The CSV integration events are triggered during the **InitDBEvents** phase, which:
- Only runs when `initDb == true`
- Reads event list from `integration.initdblist` property in JVSProperties
- For each event, looks up `integration.events.{eventName}` to get the integrator class
- Executes the CSV import using the configured consumer class

## The Solution

I've created a new `IntegrationEventsAutoConfiguration` that properly integrates CSV imports into Spring Boot's lifecycle using `ApplicationReadyEvent`, which fires **after**:
- All Spring beans are initialized
- Hibernate SessionFactory is created
- Database schema is created
- All Hitorro services are started

## Configuration

### Properties

Add to your `application.yml` or `application.properties`:

```yaml
hitorro:
  integration:
    enabled: true              # Enable integration events (default: true)
    run-on-startup: true       # Run CSV imports on startup (default: false)
```

### JVSProperties Configuration

The events are configured in your Hitorro config files (e.g., `/config/generalconfig.json`):

```json
{
  "integration": {
    "initdblist": "users, permissions, roles, htcategory, conversationtype, htcontentassettype",
    "events": {
      "htcategory": {
        "consumer": "com.hitorro.basedms.csvconsumers.CategoryCSVConsumer",
        "filename": "${HT_BIN}/data/initdb/htcategory.csv",
        "integrator": "com.hitorro.basedms.integrationevents.CSVHibernateIntegrator"
      },
      "users": {
        "consumer": "com.hitorro.basedms.csvconsumers.UserCSVConsumer",
        "filename": "${HT_BIN}/data/initdb/users.csv",
        "integrator": "com.hitorro.basedms.integrationevents.CSVHibernateIntegrator"
      }
      // ... more events
    }
  }
}
```

### Standard Event Names

The standard integration event keys are:
- **users** - User accounts
- **permissions** - System permissions
- **roles** - User roles
- **rolepermissionlist** - Role-permission mappings
- **userrolelist** - User-role mappings
- **testhierarchycat** - Test hierarchy categories
- **docparts** - Document parts
- **htcategory** - General categories
- **conversationtype** - Conversation types
- **htcontentassettype** - Content asset types
- **client** - Client records
- **rssinfeeds** - RSS feed configurations
- **personalities** - AI personalities
- **htanchor** - Anchor definitions
- **htposttype** - Post types

## Manual Triggering

You can inject `IntegrationEventsManager` to manually trigger events:

```java
@Autowired
private IntegrationEventsManager integrationEventsManager;

public void loadData() throws PropaccessError {
    // Run all configured events
    integrationEventsManager.runAllEvents();
    
    // Or run a specific event
    integrationEventsManager.runEvent("htcategory");
    
    // Check what events are configured
    List<String> events = integrationEventsManager.getConfiguredEvents();
}
```

## REST Endpoint (Optional)

You can create a REST endpoint to trigger imports:

```java
@RestController
@RequestMapping("/api/admin")
public class DataImportController {
    
    @Autowired
    private IntegrationEventsManager integrationEventsManager;
    
    @PostMapping("/import/all")
    public ResponseEntity<?> importAll() {
        try {
            integrationEventsManager.runAllEvents();
            return ResponseEntity.ok("Import complete");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Import failed: " + e.getMessage());
        }
    }
    
    @PostMapping("/import/{eventName}")
    public ResponseEntity<?> importEvent(@PathVariable String eventName) {
        try {
            boolean success = integrationEventsManager.runEvent(eventName);
            return success ? 
                ResponseEntity.ok("Event " + eventName + " completed") :
                ResponseEntity.status(500).body("Event " + eventName + " failed");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Import failed: " + e.getMessage());
        }
    }
}
```

## How It Works

### 1. Service Context Initialization

The `ServiceContextManager` calls `serviceContext.init()` which goes through all phases including `InitDBEvents`. However, this phase only runs if `initDb == true`, which in Spring Boot applications is typically `false` by default.

### 2. Application Ready Event

The `IntegrationEventsAutoConfiguration` registers an `ApplicationListener<ApplicationReadyEvent>` that:
- Waits for the application to be fully started
- Gets the `IntegrationEventsContext` singleton
- Reads the event list from `integration.initdblist` in JVSProperties
- Calls `context.runInitDBEvents()` which:
  - Iterates through each event name
  - Looks up `integration.events.{eventName}` configuration
  - Instantiates the integrator class
  - Calls `integrator.integrate()` with the event configuration

### 3. CSV Integration Process

For each event, the `CSVHibernateIntegrator`:
1. Reads the `filename` property to locate the CSV file
2. Instantiates the `consumer` class (e.g., `CategoryCSVConsumer`)
3. Passes each CSV row to the consumer
4. Consumer creates/updates Hibernate entities
5. Entities are persisted to the database

## Lifecycle Comparison

### Traditional Hitorro (BaseCommandLine)
```
1. Create ServiceContext
2. Add modules
3. Validate config keys  
4. Initialize services (runs InitDBEvents if dbInit=true)
   ↓
   InitDBEvents.execute() → IntegrationEventsContext.runInitDBEvents()
5. Start services
6. Run main logic
7. Deinit services
```

### Spring Boot Integration
```
1. Spring context starts
2. HitorroEnvironmentPostProcessor sets HT_BIN/HT_HOME
3. JVSProperties initialized from config files
4. ServiceContextManager initializes services (InitDBEvents skipped if dbInit=false)
5. Hibernate session factory created
6. Database schema created
7. Application beans initialized
8. ApplicationReadyEvent fires
   ↓
   IntegrationEventsRunner → IntegrationEventsContext.runInitDBEvents()
9. Application ready
```

## Troubleshooting

### Events Not Running

**Check property configuration:**
```bash
# In your JVSProperties config file
grep -A 20 "integration" /path/to/config/generalconfig.json
```

**Verify events are loaded:**
```java
@Autowired
private IntegrationEventsManager manager;

List<String> events = manager.getConfiguredEvents();
System.out.println("Configured events: " + events);
```

### CSV Files Not Found

Ensure paths use proper variable substitution:
```json
{
  "filename": "${HT_BIN}/data/initdb/htcategory.csv"
}
```

Variables resolved:
- `${HT_BIN}` → Value from system property or environment
- `${HT_HOME}` → Value from system property or environment

### Consumer Class Not Found

Ensure the consumer class is on the classpath:
```xml
<dependency>
    <groupId>com.hitorro</groupId>
    <artifactId>hitorro-basedms</artifactId>
    <version>3.0.0</version>
</dependency>
```

## Example Application Configuration

```yaml
# application.yml
hitorro:
  ht-bin: /opt/hitorro
  ht-home: /var/lib/hitorro
  
  services:
    enabled: true
    load:
      - com.hitorro.base.service.BasicService
      - com.hitorro.basedms.db.HibernateService
      - com.hitorro.basedms.BaseDMSService
  
  dms:
    enabled: true
    session-scope: request
    transaction-mode: spring-managed
  
  integration:
    enabled: true
    run-on-startup: true  # Run CSV imports on startup

spring:
  datasource:
    url: jdbc:h2:mem:testdb
    driver-class-name: org.h2.Driver
  
  jpa:
    hibernate:
      ddl-auto: create  # Create schema before CSV import
```

## Best Practices

1. **Development**: Set `run-on-startup: true` to auto-load test data
2. **Production**: Set `run-on-startup: false` and trigger manually via admin endpoint
3. **Testing**: Use `IntegrationEventsManager` in `@BeforeEach` to load test data
4. **CSV Files**: Keep them in version control under `data/initdb/`
5. **Idempotency**: Design consumers to handle re-running (update vs insert)

## Summary

The integration events system has been properly bridged into Spring Boot's lifecycle:

✅ **Proper Timing**: Events run after all services and database are ready  
✅ **Configuration**: Uses existing JVSProperties structure  
✅ **Manual Control**: Can be disabled and triggered manually  
✅ **Monitoring**: Clear logging of which events run  
✅ **Flexibility**: Works with or without `dbInit` flag  

This maintains compatibility with traditional Hitorro applications while providing Spring Boot-friendly configuration and lifecycle integration.
