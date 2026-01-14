# IntelliJ IDEA Debugging Setup - Summary

## What Was Done

Created a complete IntelliJ IDEA debugging setup for the `hitorro-example-springboot` project with proper `HT_BIN` and `HT_HOME` configuration.

## Files Created

### 1. Run Configuration
**Location**: `.idea/runConfigurations/HitorroExampleSpringBoot.xml`

Pre-configured Spring Boot run configuration with:
- ✅ Main class: `com.hitorro.example.HitorroExampleApplication`
- ✅ Module: `hitorro-example-springboot`
- ✅ Java: 23
- ✅ VM Options: `-server -DHT_BIN=$PROJECT_DIR$/ -DHT_HOME="$PROJECT_DIR$/../hthome" -Xmx2010M --add-opens java.base/java.lang=ALL-UNNAMED`
- ✅ Working directory: `$PROJECT_DIR$/hitorro-example-springboot`

**Also available at**: `idea/runConfigurations/HitorroExampleSpringBoot.run.xml` (backup location)

### 2. Documentation

#### Quick Start Guide
**File**: `hitorro-example-springboot/QUICK_START_INTELLIJ.md`
- 3-step visual guide to start debugging
- Troubleshooting common issues
- Pro tips for effective debugging

#### Detailed Setup Guide
**File**: `hitorro-example-springboot/INTELLIJ_SETUP.md`
- Complete configuration instructions
- Manual setup steps (if needed)
- Advanced debugging techniques
- Remote debugging setup
- Useful breakpoint locations

## How to Use

### Option 1: Automatic (Recommended)

The run configuration is already in place. Just:

1. **Open project** in IntelliJ IDEA
   ```
   File → Open → /Users/chris/hitorro
   ```

2. **Select configuration** from dropdown in toolbar
   - Look for "HitorroExampleSpringBoot"
   - Should appear automatically

3. **Click Debug** button (🐛)
   - Or press `Shift+F9`

**Done!** Application starts in debug mode with correct configuration.

### Option 2: Manual (If configuration not visible)

Follow the guide in `QUICK_START_INTELLIJ.md` to create manually.

## What the Configuration Does

### VM Options Explained

```
-server                                        # Use server JVM for better performance
-DHT_BIN=$PROJECT_DIR$/                       # Hitorro installation directory
-DHT_HOME="$PROJECT_DIR$/../hthome"           # Hitorro home directory
-Xmx2010M                                      # Maximum heap size (2GB)
--add-opens java.base/java.lang=ALL-UNNAMED   # Allow reflective access (required by Hitorro)
```

### Variable Expansion

IntelliJ automatically expands:
- `$PROJECT_DIR$` → `/Users/chris/hitorro`
- Result: `HT_BIN=/Users/chris/hitorro/`

## Verification

After starting in debug mode, verify in console:

```
✅ Good Output:
HT_BIN configured: /Users/chris/hitorro
HT_HOME configured: /Users/chris/hthome
=== Initializing JsonTypeSystem ===
✓ HT_BIN already configured: /Users/chris/hitorro
✓ HT_HOME configured: /Users/chris/hthome
✓ JsonTypeSystem initialized successfully
  Type definitions path: /Users/chris/hitorro/config/types/core/
Started HitorroExampleApplication in X.XXX seconds

❌ Bad Output:
WARNING: HT_BIN not configured
CRITICAL: HT_BIN not configured!
```

## Common Issues & Solutions

### Issue 1: Configuration Not Visible

**Cause**: IntelliJ hasn't loaded the configuration file

**Solution**:
```
1. Close IntelliJ IDEA
2. Restart IntelliJ IDEA
3. Check dropdown for "HitorroExampleSpringBoot"
```

Or:
```
File → Invalidate Caches / Restart → Invalidate and Restart
```

### Issue 2: "Module not specified"

**Cause**: Maven project not fully imported

**Solution**:
```
1. Right-click root pom.xml
2. Maven → Reload Project
3. Wait for import to complete
4. Try again
```

### Issue 3: VM Options Not Applied

**Cause**: Configuration doesn't include VM options

**Solution**:
1. Edit configuration (dropdown → "Edit Configurations...")
2. Check "VM options" field has the required options
3. If field is hidden: Click "Modify options" → "Add VM options"
4. Paste: `-server -DHT_BIN=$PROJECT_DIR$/ -DHT_HOME="$PROJECT_DIR$/../hthome" -Xmx2010M --add-opens java.base/java.lang=ALL-UNNAMED`

### Issue 4: Still Shows "HT_BIN not configured"

**Cause**: Variables not expanding or paths incorrect

**Solution - Use absolute paths**:
1. Edit configuration
2. Change VM options to:
   ```
   -server -DHT_BIN=/Users/chris/hitorro -DHT_HOME=/Users/chris/hthome -Xmx2010M --add-opens java.base/java.lang=ALL-UNNAMED
   ```

## Debugging Workflow

### Recommended Breakpoints

1. **Property Configuration**
   ```
   File: HitorroExampleApplication.java
   Method: configureHitorroSystemProperties()
   Purpose: See HT_BIN/HT_HOME being set
   ```

2. **Environment Processing**
   ```
   File: HitorroEnvironmentPostProcessor.java
   Method: postProcessEnvironment()
   Purpose: See early Spring Boot configuration
   ```

3. **JVS Initialization**
   ```
   File: JsonTypeSystemManager.java
   Method: afterPropertiesSet()
   Purpose: Verify JSON Type System starts correctly
   ```

4. **Your Controllers**
   ```
   File: ExampleController.java
   Methods: Any @GetMapping/@PostMapping
   Purpose: Debug your application logic
   ```

### Debug Controls

| Action | Shortcut | Use When |
|--------|----------|----------|
| Resume | F9 | Continue to next breakpoint |
| Step Over | F8 | Execute current line |
| Step Into | F7 | Enter method call |
| Step Out | Shift+F8 | Exit current method |
| Evaluate | Alt+F8 | Check variable values |

### Watching Variables

Right-click variables → "Add to Watches"

Useful watches:
- `System.getProperty("HT_BIN")`
- `System.getProperty("HT_HOME")`
- `properties.getJvs().getTypeDefinitionsPath()`

## Testing Endpoints

Once debugged and running:

```bash
# Check health
curl http://localhost:8080/actuator/health

# Check status
curl http://localhost:8080/api/example/status

# List services
curl http://localhost:8080/api/example/services

# Execute command
curl -X POST http://localhost:8080/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "help"}'
```

## Related Documentation

| File | Purpose |
|------|---------|
| `QUICK_START_INTELLIJ.md` | 3-step quick start for debugging |
| `INTELLIJ_SETUP.md` | Detailed IntelliJ configuration |
| `CONFIGURATION.md` | All configuration methods |
| `TROUBLESHOOTING.md` | Problem diagnosis |
| `README.md` | Project overview |

## Quick Reference

### Start Debugging
```
1. Open IntelliJ
2. Select: HitorroExampleSpringBoot
3. Click: 🐛 or Shift+F9
```

### Set Breakpoint
```
1. Open Java file
2. Click left margin (gutter) next to line number
3. Red dot = breakpoint set
```

### Evaluate Expression
```
1. Stop at breakpoint
2. Press Alt+F8
3. Type: System.getProperty("HT_BIN")
4. Click Evaluate
```

### Check Configuration
```
1. Edit Configurations (toolbar dropdown)
2. Select: HitorroExampleSpringBoot
3. Verify VM options field has all required options
```

## Success Criteria

✅ Configuration appears in IntelliJ dropdown
✅ Debug button (🐛) is enabled
✅ Application starts without "HT_BIN not configured" warnings
✅ Console shows successful initialization
✅ Breakpoints work correctly
✅ Can inspect variables during debugging
✅ Endpoints respond correctly

## Getting Help

1. **Check Quick Start**: `QUICK_START_INTELLIJ.md`
2. **Check Detailed Guide**: `INTELLIJ_SETUP.md`
3. **Configuration Issues**: `TROUBLESHOOTING.md`
4. **IntelliJ Logs**: `Help` → `Show Log in Finder/Explorer`

---

**Happy Debugging! 🎉**
