# Hitorro REST Integration Plan

## Overview

This document outlines the plan to integrate Hitorro's native REST endpoint system with Spring Boot, building on the successful CommandRegistry integration we just completed.

## Current State

### ✅ What's Already Integrated

1. **CommandRegistry Integration**
   - Commands defined with `@CommandDef` are automatically registered
   - `CommandDefScanner` scans Spring beans and core Hitorro classes
   - Commands accessible via `/api/commands/list` and `/api/commands/execute`
   - Proper execution through `CommandRegistry.execute()`
   - Results captured via `JSONResponse` with NDJSON parsing

2. **REST Support in CommandDef**
   - Commands already declare REST operations: `restOperations = {RestOperations.Get, RestOperations.Post, ...}`
   - Supported operations: Get, Post, Put, Delete, Head, LastModified
   - Commands can be queried for supported operations via `command.getRestOperations()`
   - Each command can support multiple HTTP methods

### 🎯 What Needs to Be Done

Integrate Hitorro commands as dynamic REST endpoints based on their `restOperations` declarations.

## Architecture Design

### 1. REST Endpoint Scanner

Create a `RestEndpointScanner` that:
- Scans all commands in `CommandRegistry`
- For each command, checks `command.getRestOperations()`
- Dynamically registers Spring MVC endpoints for commands that support REST

### 2. Dynamic Endpoint Registration

Use Spring's `RequestMappingHandlerMapping` to dynamically register endpoints:

```java
@Component
public class HitorroRestEndpointRegistrar implements InitializingBean {
    
    @Autowired
    private RequestMappingHandlerMapping handlerMapping;
    
    @Autowired
    private CommandRegistrationManager commandManager;
    
    @Override
    public void afterPropertiesSet() {
        CommandRegistry registry = commandManager.getCommandRegistry();
        
        for (Command command : registry.getCommands()) {
            RestOperations[] ops = command.getRestOperations();
            
            for (RestOperations op : ops) {
                registerRestEndpoint(command, op);
            }
        }
    }
    
    private void registerRestEndpoint(Command command, RestOperations operation) {
        // Create RequestMappingInfo for this command
        String path = "/api/rest/" + command.getCommand();
        RequestMethod method = toSpringHttpMethod(operation);
        
        // Register with Spring MVC handler mapping
        // Route to HitorroRestHandler.handleRequest(command, operation, params)
    }
}
```

### 3. Unified REST Handler

Create `HitorroRestHandler` to handle all dynamic REST endpoints:

```java
@RestController
public class HitorroRestHandler {
    
    public ResponseEntity<?> handleRequest(
            Command command,
            RestOperations operation,
            HttpServletRequest request,
            HttpServletResponse response) {
        
        // Parse query parameters and request body into JVS
        JVS params = extractParameters(request);
        
        // Choose appropriate Response type based on Accept header
        Response hitorroResponse = createResponse(request, operation);
        
        // Execute command
        CommandRegistry registry = CommandRegistry.getRegistry();
        boolean success = registry.execute("", command.getCommand(), params, hitorroResponse, new CommandSession());
        
        // Return result based on response type (JSON, XML, CSV, etc.)
        return buildSpringResponse(hitorroResponse, success);
    }
}
```

### 4. Content Negotiation

Support multiple response formats based on `Accept` header:
- `application/json` → `JSONResponse`
- `application/xml` → `XMLResponse`
- `text/html` → `HTMLResponse`
- `text/csv` → `CSVResponse`
- `application/octet-stream` → Binary/streaming

### 5. Streaming Support

For commands that return iterators or large datasets:
- Use Spring's `StreamingResponseBody`
- Stream NDJSON line-by-line
- Support Server-Sent Events (SSE) for real-time updates

```java
@GetMapping(value = "/api/rest/{command}", produces = MediaType.APPLICATION_NDJSON_VALUE)
public StreamingResponseBody streamCommand(@PathVariable String command, @RequestParam Map<String, String> params) {
    return outputStream -> {
        JSONResponse response = new JSONResponse(command, outputStream);
        // Execute command - response writes directly to stream
        registry.execute("", command, toJVS(params), response, new CommandSession());
        response.end();
    };
}
```

## Implementation Steps

### Phase 1: Basic REST Endpoint Registration

1. Create `HitorroRestEndpointRegistrar`
2. Scan `CommandRegistry` for commands with `restOperations`
3. Register endpoints at `/api/rest/{command.getName()}`
4. Map HTTP methods: GET, POST, PUT, DELETE
5. Create basic `HitorroRestHandler`

### Phase 2: Parameter Mapping

1. Extract query parameters → JVS
2. Extract request body (JSON) → JVS
3. Extract path variables → JVS
4. Handle multipart/form-data for file uploads

### Phase 3: Response Handling

1. Implement content negotiation
2. Support JSON, XML, HTML, CSV responses
3. Handle streaming responses (NDJSON)
4. Support binary content for file downloads

### Phase 4: Advanced Features

1. Support PUT/DELETE operations
2. Implement HEAD and OPTIONS
3. Support LastModified for caching
4. Add ETag support
5. Implement partial content (Range requests)

## Configuration

Add to `application.yml`:

```yaml
hitorro:
  rest:
    enabled: true
    base-path: /api/rest
    expose-internal: false  # Whether to expose internal commands
    content-types:
      - application/json
      - application/xml
      - text/html
      - text/csv
    streaming:
      enabled: true
      buffer-size: 8192
```

## Example Usage

Once integrated, commands automatically become REST endpoints:

```bash
# Command defined with restOperations = {RestOperations.Get}
@CommandDef(command = "user.list", 
            description = "List users",
            restOperations = {RestOperations.Get})
public List<User> listUsers(@DebugArgAno(...) String filter) { ... }

# Automatically available at:
GET /api/rest/user.list?filter=active

# Command with multiple operations
@CommandDef(command = "document.manage",
            restOperations = {RestOperations.Get, RestOperations.Post, RestOperations.Delete})
public Map<String, Object> manageDocument(...) { ... }

# Available as:
GET    /api/rest/document.manage?id=123
POST   /api/rest/document.manage
DELETE /api/rest/document.manage?id=123
```

## Benefits

1. **Automatic API Generation**: Commands automatically become REST endpoints
2. **Unified System**: Same command works via CLI, SSH, telnet, AND REST
3. **Content Negotiation**: Single endpoint, multiple formats
4. **Streaming Support**: Efficient handling of large datasets
5. **Discovery**: `/api/rest` lists all available endpoints
6. **Swagger Integration**: Auto-generate OpenAPI specs from commands

## Next Steps

To implement this:

1. Create `HitorroRestEndpointRegistrar` in `hitorro-spring-boot-autoconfigure`
2. Create `HitorroRestHandler` for dynamic request handling
3. Add configuration properties
4. Update `CommandRestController` to list REST-enabled commands
5. Add Swagger/OpenAPI documentation generation
6. Create example commands demonstrating REST capabilities

This would provide a complete, annotation-driven REST API system where commands are the single source of truth for both CLI and REST interfaces.
