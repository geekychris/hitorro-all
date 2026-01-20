# DMS Trigger Registration - Important Implementation Note

## Overview

Hitorro's DMS persistence system relies on a custom **OnTrigger** mechanism that hooks into Hibernate's event system. These triggers are responsible for critical initialization tasks like:

- **GUID generation** - Creating unique universal references for entities
- **Canonical GUID initialization** - Setting up version lineage 
- **Parent version references** - Establishing version hierarchies
- **Creator/modifier tracking** - Auditing changes
- **OnNew/OnLoad/BeforeSave/BeforeDelete event handling**

## The Problem

The triggers are registered with Hibernate via the `HTIntegrator` class, which implements Hibernate's `Integrator` interface. However, **in Spring Boot applications, this integrator is not automatically registered** with the EntityManagerFactory.

### Without Trigger Registration

When triggers aren't registered:
- `document.getGuid()` returns `null` (not generated)
- `document.getCanonicalGuid()` is `null` (not initialized) 
- `document.getParentVersion()` is `null` (not set)
- Hibernate throws: `PropertyValueException: not-null property references a null or transient value: Document.canonicalGuid`

##  Solution Options

### Option 1: Register HTIntegrator with Spring Boot (PROPER FIX)

Update `DMSAutoConfiguration` to properly register the `HTIntegrator`:

```java
@Configuration
public class HibernateConfiguration {
    
    @Bean
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(DataSource dataSource) {
        LocalContainerEntityManagerFactoryBean em = new LocalContainerEntityManagerFactoryBean();
        em.setDataSource(dataSource);
        
        // Register Hitorro's integrator
        em.setJpaVendorAdapter(new HibernateJpaVendorAdapter());
        Map<String, Object> properties = new HashMap<>();
        properties.put(AvailableSettings.INTEGRATOR_PROVIDER, 
            (IntegratorProvider) () -> Collections.singletonList(new HTIntegrator()));
        em.setJpaPropertyMap(properties);
        
        return em;
    }
}
```

### Option 2: Manual Field Initialization (CURRENT WORKAROUND)

The `DocumentManagementController` currently uses reflection to manually initialize fields:

```java
private void initializeDocumentFields(Document document) {
    // Generate GUID
    String guid = UUID.randomUUID().toString();
    setFieldViaReflection(document, "guid", guid);
    
    // Set canonicalGuid
    setFieldViaReflection(document, "canonicalGuid", guid);
    
    // Set parentVersion to self
    setFieldViaReflection(document, "parentVersion", document);
}
```

**This workaround works but bypasses the proper OnTrigger system.**

### Option 3: Use Full Service Initialization

Load `BaseDMSService` and all its dependencies (HibernateService, etc.) via the Hitorro service framework. This properly registers all triggers.

```yaml
hitorro:
  services:
    enabled: true
    load:
      - com.hitorro.basedms.db.HibernateService
      - com.hitorro.base.objects.BaseDMSService
```

**Note**: This requires all service dependencies (Jetty, etc.) which may not be desirable in Spring Boot apps.

## Current Status

### Test Environment
- ✅ `BaseDMSService.s_initialized = true` (set via `TestDMSConfiguration`)
- ✅ Manual field initialization via reflection (workaround)
- ❌ HTIntegrator not registered (triggers don't fire)
- **Result**: 13/15 tests pass

### Production Recommendation
**Implement Option 1**: Register HTIntegrator properly with Spring Boot's EntityManagerFactory. This ensures:
- Triggers fire automatically
- No reflection needed  
- Full Hitorro persistence semantics
- Proper GUID generation and tracking
- All OnTrigger events work correctly

## Files to Update

1. **`DMSAutoConfiguration.java`** - Add HTIntegrator registration
2. **`DocumentManagementController.java`** - Remove reflection workaround once triggers work
3. **Add integration test** - Verify triggers fire properly

## Benefits of Proper Trigger Registration

- **Universal ID System**: GUIDs work across all entities
- **Type Safety**: Can fetch any entity by GUID without knowing the class
- **Version Management**: Automatic version lineage tracking
- **Audit Trail**: Creator/modifier automatically set
- **Business Logic**: Custom OnTrigger handlers execute
- **Consistency**: Same behavior as standalone Hitorro apps

## References

- `HTIntegrator.java` - Registers Hibernate event listeners
- `VersionableObjectOnTriggerGeneric.java` - Implements trigger logic
- `HTHibernatePersistListener.java` - OnNew/BeforePersist events
- `HTHibernateOnSaveListener.java` - BeforeSave events
