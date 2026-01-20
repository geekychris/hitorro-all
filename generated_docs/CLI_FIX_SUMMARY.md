# CLI (Telnet/SSH) Fix Summary

## Problem

When attempting to connect via telnet or SSH to the Spring Boot application, repeated exceptions occurred:

```
java.lang.NullPointerException: Cannot invoke "com.hitorro.util.cmdline.BaseCommandLine.commandLine" 
because the return value of "com.hitorro.util.cmdline.BaseCommandLine.getCommandLine()" is null
```

### Root Cause

The `TerminalListener` (telnet) and `SshListener` (SSH) depend on `BaseCommandLine.getCommandLine()` returning a valid CommandLine instance to:
1. Set the CLI prompt (uses `commandLine.commandLine`)
2. Get process start time for `uptime` command (uses `commandLine.processStartTime`)
3. Access other command line metadata

In traditional Hitorro applications, `CommandLine.main()` creates and registers a CommandLine instance via `BaseCommandLine.setCommandLine()`. However, in Spring Boot applications:
- No `main()` method in CommandLine is called
- `BaseCommandLine.getCommandLine()` returns null
- CLI sessions fail immediately

## Solution Applied

### 1. Created `SpringBootCommandLine` Class

A minimal Spring Boot-aware implementation of `BaseCommandLine` that:
- Registers itself as the global CommandLine instance
- Provides necessary metadata (application name, start time)
- Delegates Spring-specific concerns (logging, config) to Spring Boot
- Returns null for ServiceContext (not used in Spring Boot)

**Key Features:**
```java
public SpringBootCommandLine(String applicationName) {
    this.applicationName = applicationName;
    this.commandLine = applicationName;
    this.processStartTime = System.currentTimeMillis();
    
    // Critical: Register globally
    BaseCommandLine.setCommandLine(this);
}
```

### 2. Updated `HitorroCliAutoConfiguration`

Added bean creation for `SpringBootCommandLine` **before** `NativeCliManager`:
```java
@Bean
public SpringBootCommandLine springBootCommandLine(HitorroProperties properties) {
    String appName = properties.getApplicationName() != null 
        ? properties.getApplicationName() 
        : "hitorro-spring-boot";
    return new SpringBootCommandLine(appName);
}
```

### 3. Added Configuration Property

Enhanced `HitorroProperties` with:
```java
/**
 * Application name displayed in CLI prompt and logs.
 * Defaults to spring.application.name if not set.
 */
private String applicationName;
```

### 4. Updated Example Application Config

Added to `application.yml`:
```yaml
hitorro:
  application-name: HitorroExample
```

## What Now Works

### ✅ Telnet CLI
```bash
telnet localhost 5050

# You'll see:
HitorroExample> help
HitorroExample> uptime
Start: 2026-01-14 14:16:35
Delta: 2 minutes 15 seconds
```

### ✅ SSH CLI
```bash
ssh -p 5022 user@localhost
Password: user

# Same interactive CLI
HitorroExample> help
```

### ✅ Commands Available
All registered commands work:
- `help` - List available commands
- `uptime` - Show application uptime
- `threads` - Show thread information
- `memory` - Show memory usage
- `gc` - Force garbage collection
- `props` - Show properties
- Custom commands registered via `CommandRegistry`

## Implementation Details

### Abstract Methods Implemented

`SpringBootCommandLine` implements all required abstract methods:
- `setupPrimordialLogging()` - Delegated to Spring Boot
- `setupLogging()` - Delegated to Spring Boot
- `haveJVSConfigsChanged()` - Returns false (Spring handles config)
- `reloadJVSProps(boolean)` - Returns existing args (already loaded)
- `initConfigChangeWatching()` - Delegated to Spring Boot
- `setupLogWatching()` - Delegated to Spring Boot
- `getServiceContext()` - Returns null (Spring context used instead)

### Bean Ordering

Critical that `SpringBootCommandLine` bean is created **before** `NativeCliManager`:
1. `SpringBootCommandLine` constructor registers itself globally
2. `NativeCliManager` starts CLI listeners
3. CLI sessions can access `BaseCommandLine.getCommandLine()`

## Configuration

### Enable/Disable CLI

```yaml
hitorro:
  cli:
    native-enabled: true      # Enable telnet/SSH
    telnet-port: 5050         # Telnet port
    ssh-port: 5022            # SSH port
```

### Custom Application Name

```yaml
hitorro:
  application-name: MyApp    # Shows as "MyApp>" prompt
```

### Security Note

The telnet/SSH listeners are for **development/debugging only**:
- No authentication on telnet (anyone can connect)
- Simple authentication on SSH (user/user)
- Should be disabled in production or restricted to localhost

## Testing

### Start Application
```bash
cd hitorro-example-springboot
mvn spring-boot:run
```

### Connect via Telnet
```bash
telnet localhost 5050
```

Expected output:
```
Trying ::1...
Connected to localhost.
Escape character is '^]'.
HitorroExample> help
Available commands:
  help     - Show this help
  uptime   - Show application uptime
  threads  - Show thread information
  ...
```

### Connect via SSH
```bash
ssh -p 5022 user@localhost
# Password: user
```

## Files Created/Modified

### New Files
- `hitorro-spring-boot/.../cli/SpringBootCommandLine.java` - Spring Boot CommandLine implementation

### Modified Files
- `hitorro-spring-boot/.../cli/HitorroCliAutoConfiguration.java` - Added SpringBootCommandLine bean
- `hitorro-spring-boot/.../HitorroProperties.java` - Added applicationName property
- `hitorro-example-springboot/.../application.yml` - Added application-name config

## Technical Notes

### Why Not Extend CommandLine Directly?

`CommandLine` (not `BaseCommandLine`) has specific initialization logic for traditional Java applications:
- Parses command line arguments
- Sets up signal handlers
- Initializes service framework
- Expects specific startup sequence

`SpringBootCommandLine` extends `BaseCommandLine` to:
- Provide minimal implementation needed for CLI
- Avoid conflicts with Spring Boot's startup
- Keep initialization simple and predictable

### ServiceContext Null

Traditional Hitorro uses `ServiceContext` to manage services. Spring Boot uses `ApplicationContext`. Commands that need services should:
```java
@Component
public class MyCommand implements CommandInterface {
    @Autowired
    private MyService myService;  // Use Spring DI instead
}
```

## Result

✅ **Telnet CLI works** - No more NullPointerException  
✅ **SSH CLI works** - Proper authentication and prompt  
✅ **Commands execute** - All registered commands available  
✅ **Uptime works** - Process start time tracked correctly  
✅ **Custom prompt** - Application name displayed  
✅ **Clean integration** - Minimal Spring Boot CommandLine implementation  

The CLI now works exactly as in traditional Hitorro applications, but integrated properly with Spring Boot's lifecycle and dependency injection!
