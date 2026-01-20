# Hitorro REST Endpoint Integration - Complete Summary

## Executive Summary

Hitorro has a **built-in REST endpoint system** where commands can declare which REST operations they support via the `@CommandDef` annotation's `restOperations` attribute. This is analogous to the `@CommandDef` system we just successfully integrated for CLI commands.

**Just as `@CommandDef` commands automatically appear in the CommandRegistry and are accessible via SSH/telnet CLI, REST-enabled commands should automatically become REST endpoints accessible via HTTP.**

## Current Implementation Status

### ✅ What's Already Working

1. **CommandRegistry Integration**
   - `@CommandDef` commands scan and register successfully
   - 81 total commands discovered (20 public, 61 internal)
   - Accessible via `/api/commands/list` and `/api/commands/execute`
   - Proper execution through Hitorro's CommandRegistry infrastructure
   - UI displays commands with internal filtering toggle

2. **REST Infrastructure Exists in Hitorro**
   - `RestOperations` enum: Get, Post, Put, Delete, Head, LastModified
   - `@CommandDef.restOperations` attribute declares supported HTTP methods
   - Commands can override `execute()` method with `RestOperations operation` parameter
   - Commands query: `command.getRestOperations()` and `command.getSupportsOperation(op)`

### 🎯 What Needs Implementation

**Automatic REST endpoint registration** - Commands with `restOperations` should automatically become accessible as REST endpoints, similar to how they're automatically accessible via CLI.

## How Hitorro REST Works

### 1. Command Declaration

Commands declare REST support in the `@CommandDef` annotation:

```java
@CommandDef(
    command = "enrich",
    description = "Enrich text content", 
    restOperations = {RestOperations.Get, RestOperations.Post}
)
public boolean enrich(
    @DebugArgAno(keyName = "in", ...) String input) {
    // Implementation
}
```

### 2. Command Execution with REST Context

Commands that need REST-specific behavior override `execute()` with `RestOperations` parameter:

```java
@CommandDef(command = "dms.listsessions", description = "Dump DMSSession info")
public class DumpSessionInfo extends Command {
    @Override
    public boolean execute(
            String rawValue, 
            JVS args, 
            Response response, 
            CommandSession session, 
            RestOperations operation) throws Exception {
        
        // Can branch based on operation
        switch (operation) {
            case Get:
                // Handle GET request
                break;
            case Post:
                // Handle POST request
                break;
        }
        
        return true;
    }
}
```

### 3. REST Operations Enum

```java
public enum RestOperations {
    Get,         // HTTP GET
    Put,         // HTTP PUT
    Post,        // HTTP POST
    Delete,      // HTTP DELETE
    LastModified,// HTTP Last-Modified header support
    Head         // HTTP HEAD
}
```

## Proposed Integration Architecture

### Option 1: Dynamic REST Endpoint Registration (Recommended)

**Create a Spring Boot auto-configuration that:**

1. **Scans CommandRegistry** for commands with REST operations
2. **Dynamically registers Spring MVC endpoints** using `RequestMappingHandlerMapping`
3. **Routes requests** to a unified handler that calls `CommandRegistry.execute()`

**Endpoints would be:**
```
/api/rest/{commandName}
```

**Example:**
```java
@Configuration
@ConditionalOnProperty(name = "hitorro.rest.enabled", havingValue = "true", matchIfMissing = true)
public class HitorroRestAutoConfiguration {
    
    @Bean
    public HitorroRestEndpointRegistrar restEndpointRegistrar(
            CommandRegistrationManager commandManager,
            RequestMappingHandlerMapping handlerMapping) {
        return new HitorroRestEndpointRegistrar(commandManager, handlerMapping);
    }
}
```

### Option 2: Unified REST Controller with Path Variables

**Create a single controller that handles all REST-enabled commands:**

```java
@RestController
@RequestMapping("/api/rest")
public class HitorroRestController {
    
    @Autowired
    private CommandRegistrationManager commandManager;
    
    @GetMapping("/{commandName}")
    public ResponseEntity<?> handleGet(
            @PathVariable String commandName,
            @RequestParam Map<String, String> params,
            HttpServletRequest request) {
        
        return executeCommand(commandName, RestOperations.Get, params, request);
    }
    
    @PostMapping("/{commandName}")
    public ResponseEntity<?> handlePost(
            @PathVariable String commandName,
            @RequestBody(required = false) Map<String, Object> body,
            @RequestParam Map<String, String> params,
            HttpServletRequest request) {
        
        return executeCommand(commandName, RestOperations.Post, mergeParams(params, body), request);
    }
    
    // Similar for PUT, DELETE, HEAD...
    
    private ResponseEntity<?> executeCommand(
            String commandName, 
            RestOperations operation,
            Map<String, ?> parameters,
            HttpServletRequest request) {
        
        CommandRegistry registry = commandManager.getCommandRegistry();
        Command command = registry.get(commandName);
        
        if (command == null) {
            return ResponseEntity.notFound().build();
        }
        
        if (!command.getSupportsOperation(operation)) {
            return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).build();
        }
        
        // Convert parameters to JVS
        JVS jvs = new JVS();
        parameters.forEach((k, v) -> jvs.set(k, v));
        
        // Choose response type based on Accept header
        Response hitorroResponse = createResponse(request);
        
        // Execute command with REST operation context
        boolean success = registry.execute("", commandName, jvs, hitorroResponse, new CommandSession());
        
        // Parse and return result
        return buildResponse(hitorroResponse, success);
    }
}
```

## Real Examples from Hitorro Codebase

### Example 1: Text Enrichment Commands

```java
// From BasetextService.java
@CommandDef(command = "enrich", description = "enrich", 
            restOperations = {RestOperations.Get, RestOperations.Post})
public boolean enrich(
        @DebugArgAno(keyName = "in", ...) String input) {
    return true;
}
```

**Would become:**
```
GET  /api/rest/enrich?in=text
POST /api/rest/enrich
     Body: {"in": "text"}
```

### Example 2: Session Management

```java
@CommandDef(command = "dms.listsessions", description = "Dump DMSSession info")
public class DumpSessionInfo extends Command {
    public boolean execute(..., RestOperations operation) {
        // Lists all active DMS sessions
    }
}
```

**Would become:**
```
GET /api/rest/dms.listsessions
```

## Implementation Phases

### Phase 1: Basic REST Endpoint Support ✅ Ready to Implement

1. Create `HitorroRestController` with GET/POST support
2. Add command validation (check `getSupportsOperation()`)
3. Map parameters from query string and body to JVS
4. Execute via `CommandRegistry.execute()` with `RestOperations` context
5. Return NDJSON results (reuse existing parsing)

**Estimated effort:** 2-3 hours

### Phase 2: Full HTTP Method Support

1. Add PUT, DELETE, HEAD handlers
2. Implement LastModified header support
3. Add OPTIONS for CORS
4. Proper HTTP status code mapping

**Estimated effort:** 1-2 hours

### Phase 3: Content Negotiation

1. Support multiple response formats based on `Accept` header:
   - `application/json` → JSONResponse
   - `application/xml` → XMLResponse
   - `text/html` → HTMLResponse
   - `text/csv` → CSVResponse
2. Use Hitorro's existing Response classes

**Estimated effort:** 2-3 hours

### Phase 4: Advanced Features

1. Streaming responses with `StreamingResponseBody`
2. File upload/download support
3. ETag and conditional request support
4. OpenAPI/Swagger documentation generation
5. REST endpoint discovery at `/api/rest`

**Estimated effort:** 4-6 hours

## Configuration

Add to `application.yml`:

```yaml
hitorro:
  rest:
    enabled: true
    base-path: /api/rest
    expose-internal: false  # Filter internal commands
    supported-operations:
      - Get
      - Post
      - Put
      - Delete
      - Head
```

## Discovery API

Create `/api/rest` endpoint to list all REST-enabled commands:

```
GET /api/rest
```

Returns:
```json
{
  "endpoints": [
    {
      "path": "/api/rest/enrich",
      "command": "enrich",
      "description": "Enrich text content",
      "methods": ["GET", "POST"],
      "parameters": [
        {"name": "in", "type": "string", "required": true, "description": "Input text"}
      ]
    },
    {
      "path": "/api/rest/dms.listsessions",
      "command": "dms.listsessions",
      "description": "Dump DMSSession info",
      "methods": ["GET"],
      "parameters": []
    }
  ]
}
```

## React UI Integration

Update the Commands page to show REST endpoint information:

1. **REST Badge**: Show which commands are REST-enabled
2. **Supported Methods**: Display GET, POST, PUT, DELETE badges
3. **REST URL**: Show the endpoint URL for copying
4. **Try It**: Allow testing REST endpoints directly from UI

## Benefits

1. **Automatic API**: Commands automatically become REST endpoints
2. **Unified System**: Same code for CLI, SSH, and REST
3. **Type Safety**: Reuse existing parameter validation
4. **Consistent**: Same execution path as CLI commands
5. **Discoverable**: REST endpoints automatically documented

## Next Steps

1. ✅ Review this document
2. Create `HitorroRestController` (Phase 1)
3. Test with existing REST-enabled commands (enrich, fi, async, dms.listsessions)
4. Add discovery endpoint `/api/rest`
5. Update React UI to show REST endpoints

## Questions to Clarify

1. **Namespace conventions**: Should we use `/api/rest/{command}` or mirror the command structure like `/api/rest/dms/listsessions`?

2. **Content-Type defaults**: Should commands default to JSON responses or let the command decide?

3. **Authentication**: Should REST endpoints use the same authentication as CLI (CommandSession)?

4. **Error handling**: Should we return Hitorro-style errors or Spring Boot standard error responses?

---

**This REST integration will complete the Hitorro Spring Boot integration, making commands accessible via:**
- ✅ SSH CLI (port 2222)
- ✅ Telnet CLI (port 5050)
- ✅ REST API `/api/commands/execute` (generic executor)
- 🎯 REST API `/api/rest/{command}` (direct REST endpoints)
