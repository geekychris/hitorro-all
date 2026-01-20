# Hitorro REST Integration - Quick Reference

## TL;DR

Add `restOperations` to `@CommandDef` → command becomes REST endpoint automatically.

```java
@CommandDef(
    command = "my.command",
    restOperations = {RestOperations.Get}
)
public String myCommand(@DebugArgAno(...) String param) {
    return "result";
}
```

**Instantly available at:** `GET /api/rest/my.command?param=value`

---

## Quick Examples

### 1. Simple GET Command

```java
@CommandDef(command = "echo", restOperations = {RestOperations.Get})
public String echo(@DebugArgAno(keyName = "msg") String msg) {
    return msg;
}
```
```bash
curl "http://localhost:8080/api/rest/echo?msg=hello"
```

### 2. POST with JSON Body

```java
@CommandDef(command = "add", restOperations = {RestOperations.Post})
public int add(@DebugArgAno(keyName = "a") int a,
               @DebugArgAno(keyName = "b") int b) {
    return a + b;
}
```
```bash
curl -X POST http://localhost:8080/api/rest/add \
  -H "Content-Type: application/json" \
  -d '{"a": 10, "b": 20}'
```

### 3. Streaming CSV Export ⭐

```java
@CommandDef(command = "export", restOperations = {RestOperations.Get})
public class ExportCommand extends Command {
    public boolean execute(..., Response response, ...) {
        HttpServletResponse resp = response.getHttpResponse();
        resp.setContentType("text/csv");
        
        try (PrintWriter w = resp.getWriter()) {
            w.println("id,name,value");
            for (Data d : bigDataset()) {
                w.println(d.toCsv());
                if (d.id() % 100 == 0) w.flush();  // Stream!
            }
        }
        return true;
    }
}
```
```bash
curl "http://localhost:8080/api/rest/export" > data.csv
```

### 4. File Download

```java
@CommandDef(command = "download", restOperations = {RestOperations.Get})
public class DownloadCommand extends Command {
    public boolean execute(..., Response response, ...) {
        HttpServletResponse resp = response.getHttpResponse();
        resp.setContentType("application/pdf");
        resp.setHeader("Content-Disposition", "attachment; filename=\"report.pdf\"");
        
        try (ServletOutputStream out = resp.getOutputStream()) {
            out.write(generatePdf());
        }
        return true;
    }
}
```
```bash
curl "http://localhost:8080/api/rest/download" > report.pdf
```

### 5. Multiple HTTP Methods

```java
@CommandDef(
    command = "resource",
    restOperations = {RestOperations.Get, RestOperations.Post, 
                     RestOperations.Put, RestOperations.Delete}
)
public class ResourceCommand extends Command {
    public boolean execute(..., RestOperations op, ...) {
        switch (op) {
            case Get: return handleGet();
            case Post: return handleCreate();
            case Put: return handleUpdate();
            case Delete: return handleDelete();
        }
        return false;
    }
}
```

---

## Configuration

```yaml
hitorro:
  rest:
    enabled: true              # Enable/disable REST
    base-path: /api/rest       # Endpoint base path
    expose-internal: false     # Hide internal commands
```

---

## Discovery

List all REST endpoints:
```bash
curl http://localhost:8080/api/rest
```

Returns:
```json
{
  "totalEndpoints": 20,
  "endpoints": [
    {
      "path": "/echo",
      "command": "echo",
      "methods": ["GET"],
      "parameters": [...]
    }
  ]
}
```

---

## Response Formats

### Structured JSON (Default)

Command uses `response.addRow()`:
```json
{
  "success": true,
  "command": "echo",
  "operation": "Get",
  "result": {"value": "hello"},
  "executionTimeMs": 3
}
```

### Streaming (Direct Servlet Access)

Command uses `response.getHttpResponse()`:
- Raw content streamed directly
- No JSON wrapper
- Response committed by command

---

## Testing

### Run Tests
```bash
cd hitorro-spring-boot/hitorro-spring-boot-autoconfigure
mvn test -Dtest=HitorroRestControllerTest
```

### Test Streaming
```java
@Test
public void testStreaming() throws Exception {
    MvcResult result = mockMvc.perform(get("/api/rest/stream"))
        .andReturn();
    
    assertTrue(result.getResponse().isCommitted());
}
```

---

## Cheat Sheet

| Feature | Code |
|---------|------|
| GET endpoint | `restOperations = {RestOperations.Get}` |
| POST endpoint | `restOperations = {RestOperations.Post}` |
| Multiple methods | `restOperations = {Get, Post, Put}` |
| Access request | `response.getHttpRequest()` |
| Access response | `response.getHttpResponse()` |
| Stream data | `resp.getOutputStream().write(...)` |
| Flush stream | `out.flush()` |
| Set headers | `resp.setHeader("X-Custom", "value")` |
| Content type | `resp.setContentType("text/csv")` |

---

## Error Codes

| Code | Meaning | When |
|------|---------|------|
| 200 | Success | Command executed successfully |
| 404 | Not Found | Command doesn't exist |
| 405 | Method Not Allowed | HTTP method not supported |
| 500 | Internal Error | Command threw exception |

---

## Common Patterns

### Pattern 1: Simple Data Return
```java
@CommandDef(command = "data", restOperations = {Get})
public Map<String, Object> getData() {
    return Map.of("key", "value");
}
```

### Pattern 2: Streaming Large Dataset
```java
public boolean execute(..., Response response, ...) {
    HttpServletResponse resp = response.getHttpResponse();
    try (PrintWriter w = resp.getWriter()) {
        for (Item item : millionsOfItems()) {
            w.println(item.toJson());
            if (item.id() % 1000 == 0) w.flush();
        }
    }
    return true;
}
```

### Pattern 3: File Upload
```java
public boolean execute(..., Response response, ...) {
    HttpServletRequest req = response.getHttpRequest();
    if (ServletFileUpload.isMultipartContent(req)) {
        List<FileItem> items = new ServletFileUpload().parseRequest(req);
        // Process files
    }
    return true;
}
```

### Pattern 4: Conditional Behavior
```java
public boolean execute(..., Response response, RestOperations op, ...) {
    HttpServletResponse resp = response.getHttpResponse();
    
    if (resp != null) {
        // REST call - stream response
        resp.setContentType("text/csv");
        streamCsv(resp.getOutputStream());
    } else {
        // CLI call - use response
        response.addRow("message", "Use REST for export");
    }
    return true;
}
```

---

## 🎯 Key Takeaways

1. **Zero Boilerplate** - Add `restOperations`, get REST endpoint
2. **Streaming Support** - Use `getHttpResponse()` for large data
3. **Same Code** - Works for CLI and REST
4. **Auto Discovery** - `/api/rest` lists all endpoints
5. **Type Safe** - Reuses `@DebugArgAno` validation

---

## 📚 Full Documentation

- **HITORRO_REST_IMPLEMENTATION_COMPLETE.md** - Complete implementation details
- **HITORRO_REST_STREAMING_SUPPORT.md** - Streaming and servlet usage
- **HITORRO_REST_TEST_GUIDE.md** - Test suite and examples
- **HITORRO_REST_FINAL_SUMMARY.md** - Executive summary

---

## 🚀 Get Started in 3 Steps

1. **Add annotation:**
   ```java
   @CommandDef(command = "my.cmd", restOperations = {Get})
   ```

2. **Implement method:**
   ```java
   public String execute(@DebugArgAno(keyName = "p") String p) {
       return "result";
   }
   ```

3. **Call endpoint:**
   ```bash
   curl "http://localhost:8080/api/rest/my.cmd?p=value"
   ```

**That's it!** ✅
