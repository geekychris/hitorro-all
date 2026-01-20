# Backend Startup Guide

## Starting the Hitorro Spring Boot Application

### Method 1: Maven (Recommended for Development)

```bash
cd /Users/chris/hitorro/hitorro-example-springboot
mvn spring-boot:run
```

### Method 2: Using the Startup Script

```bash
cd /Users/chris/hitorro
./start-backend.sh
```

### Method 3: Build and Run JAR

```bash
cd /Users/chris/hitorro/hitorro-example-springboot
mvn clean package -DskipTests
java -jar target/hitorro-example-springboot-1.0.0.jar
```

## Expected Startup Sequence

1. **Compilation** (if using mvn spring-boot:run)
   ```
   [INFO] Compiling 10 source files
   [INFO] BUILD SUCCESS
   ```

2. **Spring Boot Banner**
   ```
     .   ____          _            __ _ _
    /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
   ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
    \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
     '  |____| .__|_| |_|_| |_\__, | / / / /
    =========|_|==============|___/=/_/_/_/
    :: Spring Boot ::                (v3.2.2)
   ```

3. **Application Starting**
   ```
   INFO c.h.example.HitorroExampleApplication : Starting HitorroExampleApplication
   ```

4. **Database Initialization**
   ```
   INFO com.zaxxer.hikari.HikariDataSource : HikariPool-1 - Starting...
   INFO o.s.b.a.h2.H2ConsoleAutoConfiguration : H2 console available at '/h2-console'
   ```

5. **Hibernate Schema Updates** (May show warnings - these are normal!)
   ```
   WARN o.h.t.s.i.ExceptionHandlerLoggedImpl : GenerationTarget encountered exception accepting command
   Error: Index "name_idx" already exists
   ```
   **Note**: These warnings are NORMAL when using `ddl-auto: update`. Hibernate is trying to create indexes that already exist from previous runs. The application continues starting.

6. **Hitorro Services Initialization**
   ```
   INFO c.h.s.a.s.HitorroServiceAutoConfiguration : Initializing Hitorro Services...
   INFO c.h.b.o.BaseDMSService : BaseDMSService initialized
   ```

7. **Controllers & REST Endpoints**
   ```
   INFO c.h.e.c.DocumentManagementController : Document Management Controller initialized
   INFO c.h.e.c.CommandDefRestController : Registered command: add -> DemoCommands.add
   ```

8. **Application Started** (SUCCESS!)
   ```
   INFO c.h.example.HitorroExampleApplication : Started HitorroExampleApplication in X.XXX seconds
   INFO o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port 8080 (http)
   ```

## Verifying Startup

### Check if Application is Running

```bash
# Check if port 8080 is listening
lsof -i :8080

# Or use curl
curl http://localhost:8080/actuator/health
```

**Expected Response:**
```json
{
  "status": "UP"
}
```

### Access Key Endpoints

1. **Swagger UI**: http://localhost:8080/swagger-ui.html
2. **H2 Console**: http://localhost:8080/h2-console
3. **Health Check**: http://localhost:8080/actuator/health
4. **API Docs**: http://localhost:8080/api-docs

### Test REST Endpoints

```bash
# List JVS types
curl http://localhost:8080/api/jvs/types

# List commands
curl http://localhost:8080/api/commands/list

# Get DMS containers
curl http://localhost:8080/api/dms/containers
```

## Common Issues and Solutions

### Issue 1: Index Already Exists Warnings

**Symptoms:**
```
WARN o.h.t.s.i.ExceptionHandlerLoggedImpl : Index "name_idx" already exists
```

**Solution:**
- **This is NORMAL** - Not an error, just a warning
- Occurs when using `ddl-auto: update` with existing database
- Application continues starting normally
- To eliminate warnings, delete `./data/hitorrodb.mv.db` for fresh start

### Issue 2: Port 8080 Already in Use

**Symptoms:**
```
java.net.BindException: Address already in use
```

**Solution:**
```bash
# Find process using port 8080
lsof -ti:8080

# Kill the process
kill -9 $(lsof -ti:8080)

# Or use different port in application.yml
server:
  port: 8081
```

### Issue 3: HT_BIN / HT_HOME Not Found

**Symptoms:**
```
WARNING: HT_BIN not configured. Using default: /Users/chris/hitorro
```

**Solution:**
- These warnings are informational
- Defaults are set in `application.yml`:
  ```yaml
  hitorro:
    ht-bin: /Users/chris/hitorro
    ht-home: /Users/chris/hthome
  ```
- Or set environment variables:
  ```bash
  export HT_BIN=/Users/chris/hitorro
  export HT_HOME=/Users/chris/hthome
  ```

### Issue 4: Database Lock Error

**Symptoms:**
```
Database may be already in use: ...hitorrodb.lock.db
```

**Solution:**
```bash
# Remove lock file
rm ./data/hitorrodb.lock.db

# Or kill any stale H2 processes
ps aux | grep h2 | grep -v grep | awk '{print $2}' | xargs kill -9
```

### Issue 5: Out of Memory

**Symptoms:**
```
java.lang.OutOfMemoryError: Java heap space
```

**Solution:**
```bash
# Increase heap size
export MAVEN_OPTS="-Xmx2g -Xms512m"
mvn spring-boot:run

# Or for JAR:
java -Xmx2g -Xms512m -jar target/hitorro-example-springboot-1.0.0.jar
```

### Issue 6: Compilation Errors

**Symptoms:**
```
[ERROR] COMPILATION ERROR
```

**Solution:**
```bash
# Clean and rebuild
mvn clean compile

# If still fails, check Java version
java -version  # Should be Java 17 or higher

# Update to Java 17
brew install openjdk@17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

## Fresh Start (Reset Database)

If you want to start with a clean database:

```bash
# Stop application (Ctrl+C)

# Delete database files
rm -rf ./data/hitorrodb.mv.db ./data/hitorrodb.trace.db

# Restart application
mvn spring-boot:run
```

## Monitoring Application

### View Logs in Real-Time

```bash
# If running via script, logs go to console

# If running as background service, tail logs
tail -f nohup.out
```

### Check Application Metrics

```bash
curl http://localhost:8080/actuator/metrics
curl http://localhost:8080/actuator/metrics/jvm.memory.used
curl http://localhost:8080/actuator/metrics/http.server.requests
```

## Running in Background

### Using nohup

```bash
cd /Users/chris/hitorro/hitorro-example-springboot
nohup mvn spring-boot:run > hitorro.log 2>&1 &

# View logs
tail -f hitorro.log

# Stop
ps aux | grep "spring-boot:run" | grep -v grep | awk '{print $2}' | xargs kill
```

### Using screen/tmux

```bash
# Start screen session
screen -S hitorro

# Run application
cd /Users/chris/hitorro/hitorro-example-springboot
mvn spring-boot:run

# Detach: Ctrl+A, then D
# Reattach: screen -r hitorro
```

## Performance Tips

1. **Skip Tests**: `mvn spring-boot:run -DskipTests`
2. **Increase Memory**: `export MAVEN_OPTS="-Xmx2g"`
3. **Use Dev Profile**: Add `-Dspring.profiles.active=dev` for development-specific settings
4. **Hot Reload**: Consider using Spring Boot DevTools for auto-restart

## Next Steps

Once the backend is running:

1. Verify Swagger UI: http://localhost:8080/swagger-ui.html
2. Start the React frontend (see react-app/README.md)
3. Test the integrated application at http://localhost:3000
4. Use H2 Console to inspect database: http://localhost:8080/h2-console

## Summary

The Hitorro Spring Boot application should start successfully despite some Hibernate index warnings (which are normal). If you see the "Started HitorroExampleApplication" message, the backend is ready!
