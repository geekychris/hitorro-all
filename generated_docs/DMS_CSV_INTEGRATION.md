# DMS CSV Integration and Data Loading

## Current Status

**CSV Integration is NOT running in the Spring Boot tests.**

The integration events (`stores`, `domaininfo`, `users`) require:
1. Integration event registration with `IntegrationEventsContext`
2. JSON configuration specifying the CSV file paths and consumer classes
3. The full Hitorro service framework to be loaded

## What's Actually Running

Currently, the test configuration only:
- ✅ Sets `BaseDMSService.s_initialized = true`
- ✅ Enables the OnTrigger system (GUID generation, canonical fields)
- ✅ Registers HTIntegrator (Hibernate event listeners)
- ❌ Does NOT load CSV data (Stores, Users, DomainInfo)

## Impact

Without CSV data loading:
- **GUID generation works** - Triggers create GUIDs correctly
- **Basic CRUD works** - Create, read, update, delete documents
- **Versioning works** - Document versioning functions
- **Categories may fail** - Domain values not loaded from DomainInfo CSV
- **Store references are null** - `StoreUtil.getDefaultStore()` returns null
- **Index names not set** - Requires default Store configuration

## How CSV Integration Works

### 1. Integration Event Registration

Integration events must be registered with JSON configuration:

```json
{
  "stores": {
    "integrator": "com.hitorro.basedms.integrationevents.CSVHibernateIntegrator",
    "consumer": "com.hitorro.basedms.StoreConsumer",
    "filename": "${HT_BIN}/config/stores.csv"
  },
  "domaininfo": {
    "integrator": "com.hitorro.basedms.integrationevents.CSVHibernateIntegrator",
    "consumer": "com.hitorro.basedms.DomainInfoConsumer",
    "filename": "${HT_BIN}/config/domaininfo.csv"
  }
}
```

### 2. CSV File Processing

The `CSVHibernateIntegrator`:
1. Reads the CSV file
2. Creates consumer instance (e.g., `StoreConsumer`)
3. For each CSV row:
   - Checks if entity exists
   - Creates new entity or updates existing
   - Persists to database via DMSSession

### 3. Required Components

- `CSVHibernateLoader` - Parses CSV files
- `CSVHibernateLoaderConsumer` - Converts CSV rows to entities
- Consumer implementations: `StoreConsumer`, `DomainInfoConsumer`, `UsersConsumer`
- Integration event registration in `IntegrationEventsContext`

## To Enable CSV Loading

### Option 1: Load Full BaseDMSService (NOT WORKING - needs Jetty)

```yaml
hitorro:
  services:
    enabled: true
    db-init: true
    load:
      - com.hitorro.base.objects.BaseDMSService
```

This fails because BaseDMSService depends on:
- HibernateService
- BasePersistenceService
- SchedulerService
- WorkflowService
- **ResourceService** ← Requires Jetty

### Option 2: Register Integration Events Manually (COMPLEX)

Would need to:
1. Register CSVHibernateIntegrator with IntegrationEventsContext
2. Provide JSON configuration for each event
3. Ensure CSV files exist at configured paths
4. Handle DMSSession creation/management

### Option 3: Pre-populate Database (RECOMMENDED FOR TESTS)

Instead of CSV loading, pre-populate test data:

```java
@PostConstruct
public void setupTestData() {
    DMSSession session = sessionFactory.createSession();
    try {
        // Create default Store
        Store store = new Store();
        store.setName("default");
        session.persist(store);
        
        // Create test domains
        DomainInfo priority = new DomainInfo();
        priority.setDomain("priority");
        priority.setValue("high");
        session.persist(priority);
        
        session.commit();
    } finally {
        session.close();
    }
}
```

## Production Recommendations

For production Spring Boot applications using Hitorro DMS:

1. **Use Spring Boot's DataSource initialization**
   - Place CSV data in `src/main/resources/data.sql`
   - Let Spring Boot load on startup

2. **Or use Liquibase/Flyway**
   - Manage schema and reference data with migrations
   - Version control your seed data

3. **Or load full Hitorro service framework**
   - Include all dependencies (Jetty, etc.)
   - Configure via `hitorro.services.load`
   - Use Hitorro's native CSV integration

## Current Test Strategy

The tests work without CSV data by:
- Testing core DMS functionality (CRUD, versioning, queries)
- Skipping tests that require specific domain values
- Using minimal test data created programmatically
- Focusing on verifying OnTrigger system and basic persistence

**Result: 12/15 tests pass (80%)** with triggers and basic DMS working correctly.
