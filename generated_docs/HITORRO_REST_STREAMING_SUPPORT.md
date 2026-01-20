# Hitorro REST Streaming Support

## Overview

The Hitorro REST controller **fully supports** commands that need direct access to `HttpServletRequest` and `HttpServletResponse` for:
- **Streaming responses** (large datasets, real-time data)
- **File downloads** (PDFs, images, CSV exports)
- **Custom content types** (binary data, multipart)
- **Custom headers** (Content-Disposition, Cache-Control, etc.)
- **Chunked transfer encoding**

## How It Works

### 1. Response Object Has Servlet Access

The Hitorro `Response` base class already provides:

```java
public abstract class Response {
    protected HttpServletResponse httpResponse;
    protected HttpServletRequest httpRequest;
    
    public HttpServletRequest getHttpRequest() {
        return httpRequest;
    }
    
    public HttpServletResponse getHttpResponse() {
        return httpResponse;
    }
}
```

### 2. HitorroRestController Sets Servlet Objects

When executing a command, the controller:

```java
// Create response handler
JSONResponse hitorroResponse = new JSONResponse(commandName, outputStream);

// CRITICAL: Set servlet objects for commands that need them
hitorroResponse.setHttpRequest(request);
hitorroResponse.setHttpResponse(servletResponse);

// Execute command - command can now access servlet objects
registry.execute("", commandName, jvs, hitorroResponse, session);

// Check if command handled response directly
if (servletResponse.isCommitted()) {
    // Command wrote directly to response - don't return ResponseEntity
    return null;
}
```

### 3. Commands Can Use Servlet Objects Directly

Commands can access the servlet objects and write directly to the response:

```java
@CommandDef(
    command = "export.large.dataset",
    description = "Export large dataset as streaming CSV",
    restOperations = {RestOperations.Get}
)
public class StreamingExportCommand extends Command {
    
    @Override
    public boolean execute(String rawValue, JVS args, Response response, 
                          CommandSession session, RestOperations operation) {
        
        // Get servlet response for streaming
        HttpServletResponse servletResponse = response.getHttpResponse();
        
        if (servletResponse != null) {
            try {
                // Set headers for file download
                servletResponse.setContentType("text/csv");
                servletResponse.setHeader("Content-Disposition", 
                    "attachment; filename=\"export.csv\"");
                
                // Get output stream and write directly
                ServletOutputStream out = servletResponse.getOutputStream();
                
                // Stream data in chunks
                out.println("id,name,value");
                for (int i = 0; i < 1_000_000; i++) {
                    out.printf("%d,Item_%d,%d%n", i, i, i * 100);
                    
                    // Flush periodically for streaming
                    if (i % 1000 == 0) {
                        out.flush();
                    }
                }
                
                out.flush();
                // Response is now committed - controller won't send additional data
                return true;
                
            } catch (IOException e) {
                logger.error("Error streaming data", e);
                return false;
            }
        }
        
        // Fallback to normal response if servlet not available
        response.addRow("Error", "Servlet response not available");
        return false;
    }
}
```

## Use Cases

### 1. Large Dataset Export (Streaming CSV)

```java
@CommandDef(command = "export.csv", restOperations = {RestOperations.Get})
public class CsvExportCommand extends Command {
    
    public boolean execute(..., Response response, ...) {
        HttpServletResponse servletResp = response.getHttpResponse();
        servletResp.setContentType("text/csv");
        servletResp.setHeader("Content-Disposition", "attachment; filename=\"data.csv\"");
        
        try (ServletOutputStream out = servletResp.getOutputStream()) {
            // Stream millions of rows without buffering in memory
            streamCsvData(out);
            return true;
        }
    }
}
```

**Access via REST:**
```bash
curl http://localhost:8080/api/rest/export.csv > data.csv
```

### 2. File Download (PDF, Images, etc.)

```java
@CommandDef(command = "download.report", restOperations = {RestOperations.Get})
public class DownloadReportCommand extends Command {
    
    public boolean execute(..., Response response, ...) {
        HttpServletResponse servletResp = response.getHttpResponse();
        
        servletResp.setContentType("application/pdf");
        servletResp.setHeader("Content-Disposition", "attachment; filename=\"report.pdf\"");
        
        try (ServletOutputStream out = servletResp.getOutputStream()) {
            byte[] pdfData = generatePdfReport();
            out.write(pdfData);
            return true;
        }
    }
}
```

**Access via REST:**
```bash
curl http://localhost:8080/api/rest/download.report > report.pdf
```

### 3. Server-Sent Events (SSE)

```java
@CommandDef(command = "events.stream", restOperations = {RestOperations.Get})
public class EventStreamCommand extends Command {
    
    public boolean execute(..., Response response, ...) {
        HttpServletResponse servletResp = response.getHttpResponse();
        
        servletResp.setContentType("text/event-stream");
        servletResp.setCharacterEncoding("UTF-8");
        servletResp.setHeader("Cache-Control", "no-cache");
        servletResp.setHeader("Connection", "keep-alive");
        
        try (PrintWriter writer = servletResp.getWriter()) {
            // Send events as they occur
            for (int i = 0; i < 10; i++) {
                writer.write("data: Event " + i + "\n\n");
                writer.flush();
                Thread.sleep(1000);  // Simulate real-time events
            }
            return true;
        }
    }
}
```

**Access via REST:**
```bash
curl http://localhost:8080/api/rest/events.stream
```

### 4. Multipart File Upload (POST/PUT)

```java
@CommandDef(command = "upload.file", restOperations = {RestOperations.Post, RestOperations.Put})
public class FileUploadCommand extends Command {
    
    public boolean execute(..., Response response, ...) {
        HttpServletRequest req = response.getHttpRequest();
        
        if (req != null && ServletFileUpload.isMultipartContent(req)) {
            try {
                ServletFileUpload upload = new ServletFileUpload(new DiskFileItemFactory());
                List<FileItem> items = upload.parseRequest(req);
                
                for (FileItem item : items) {
                    if (!item.isFormField()) {
                        String fileName = item.getName();
                        InputStream stream = item.getInputStream();
                        // Process uploaded file
                        processUpload(fileName, stream);
                    }
                }
                
                response.addRow("success", "File uploaded");
                return true;
                
            } catch (Exception e) {
                response.addRow("error", e.getMessage());
                return false;
            }
        }
        
        response.addRow("error", "Not multipart request");
        return false;
    }
}
```

**Access via REST:**
```bash
curl -X POST http://localhost:8080/api/rest/upload.file \
  -F "file=@document.pdf"
```

### 5. Custom Headers and Caching

```java
@CommandDef(command = "image.thumbnail", restOperations = {RestOperations.Get})
public class ThumbnailCommand extends Command {
    
    public boolean execute(..., Response response, ...) {
        HttpServletResponse servletResp = response.getHttpResponse();
        HttpServletRequest req = response.getHttpRequest();
        
        // Check If-Modified-Since header
        long ifModifiedSince = req.getDateHeader("If-Modified-Since");
        long lastModified = getImageLastModified();
        
        if (ifModifiedSince >= lastModified) {
            servletResp.setStatus(HttpServletResponse.SC_NOT_MODIFIED);
            return true;
        }
        
        // Set caching headers
        servletResp.setContentType("image/jpeg");
        servletResp.setDateHeader("Last-Modified", lastModified);
        servletResp.setHeader("Cache-Control", "max-age=3600");
        
        try (ServletOutputStream out = servletResp.getOutputStream()) {
            byte[] imageData = generateThumbnail();
            out.write(imageData);
            return true;
        }
    }
}
```

## Benefits

1. **No Special Cases** - Commands work the same way via CLI, SSH, and REST
2. **Full Control** - Commands have complete control over HTTP response
3. **Memory Efficient** - Stream large data without buffering
4. **Standard HTTP** - Use standard servlet APIs, no custom abstractions
5. **Backward Compatible** - Existing commands continue to work

## How to Detect REST vs CLI

Commands can detect if they're being called via REST:

```java
public boolean execute(..., Response response, ...) {
    HttpServletResponse servletResp = response.getHttpResponse();
    
    if (servletResp != null) {
        // Called via REST - can use servlet features
        servletResp.setContentType("application/json");
        // ... streaming, headers, etc.
    } else {
        // Called via CLI (SSH/telnet)
        // Use normal Response methods
        response.addRow("key", "value");
    }
    
    return true;
}
```

## Response Handling Flow

1. **Command doesn't use servlet objects**
   - Writes to Response using `addRow()`, etc.
   - Controller captures output via ByteArrayOutputStream
   - Returns structured JSON response

2. **Command uses servlet objects**
   - Writes directly to `HttpServletResponse.getOutputStream()`
   - Response becomes "committed"
   - Controller detects committed response and returns `null`
   - Spring knows not to write additional data

## Testing Streaming Commands

```bash
# Test CSV export (should stream immediately)
curl http://localhost:8080/api/rest/export.csv

# Test file download
curl http://localhost:8080/api/rest/download.report -o report.pdf

# Test SSE (should show events in real-time)
curl -N http://localhost:8080/api/rest/events.stream

# Test with progress tracking
curl http://localhost:8080/api/rest/process.large.dataset \
  --no-buffer \
  --output result.json
```

## Implementation Details

### Controller Check for Committed Response

```java
// After command execution
if (servletResponse.isCommitted()) {
    logger.debug("Response already committed by command {} - " +
                "command handled response directly", commandName);
    // Return null - Spring won't write anything else
    return null;
}

// If not committed, parse output and return JSON
Object result = parseNDJSON(outputStream.toString("UTF-8"));
return ResponseEntity.ok(Map.of(
    "success", success,
    "result", result,
    "executionTimeMs", executionTime
));
```

## Conclusion

The Hitorro REST integration **fully supports** all advanced HTTP features through the existing `Response.getHttpRequest()` and `Response.getHttpResponse()` methods. Commands can:

- ✅ Stream large datasets
- ✅ Send files for download
- ✅ Handle file uploads
- ✅ Send Server-Sent Events
- ✅ Set custom headers
- ✅ Implement caching (ETag, Last-Modified)
- ✅ Return binary data
- ✅ Use chunked transfer encoding

**No additional infrastructure needed** - the servlet objects are already there!
