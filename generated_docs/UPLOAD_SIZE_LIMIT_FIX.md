# Upload Size Limit Fix - 413 Payload Too Large ✅

## Problem

When uploading large files, users got:
```
413 Payload Too Large
Failed to load resource: the server responded with a status of 413 (Payload Too Large)
```

## Root Cause

Spring Boot has **default upload size limits**:
- **max-file-size**: 1 MB (default)
- **max-request-size**: 10 MB (default)

Any file larger than 1 MB would be rejected by the server before reaching the upload handler.

## Solution

Increased upload limits to **500 MB** in `application.yml`

### Configuration Changes

Added three levels of configuration to handle large files:

#### 1. Spring Multipart Configuration
```yaml
spring:
  servlet:
    multipart:
      enabled: true
      max-file-size: 500MB        # Maximum file size (was 1MB default)
      max-request-size: 500MB     # Maximum request size (was 10MB default)
      file-size-threshold: 2KB    # Files larger than this written to disk
```

#### 2. Tomcat Server Configuration
```yaml
server:
  tomcat:
    max-swallow-size: 500MB       # Maximum size for POST data
    max-http-form-post-size: 500MB  # Maximum size for POST requests
```

These prevent Tomcat from rejecting large uploads at the HTTP layer.

### UI Enhancement

Added helpful feedback in the upload dialog:

**Before Upload**:
```
Upload Content
Maximum file size: 500 MB
[File picker]
```

**After Selecting File**:
```
Selected: large-file.pdf (245.3 MB)
```

**If File Too Large**:
```
Selected: huge-file.pdf (678.5 MB) ⚠️ FILE TOO LARGE!
```

The UI now:
- Shows the 500 MB limit
- Displays size in KB or MB (auto-converts)
- **Red warning** if file exceeds limit
- Prevents confusion before upload attempt

## Technical Details

### Size Limits Explained

| Setting | Purpose | Old Limit | New Limit |
|---------|---------|-----------|-----------|
| `max-file-size` | Single file size | 1 MB | 500 MB |
| `max-request-size` | Total request size | 10 MB | 500 MB |
| `max-swallow-size` | Tomcat POST limit | 2 MB | 500 MB |
| `max-http-form-post-size` | Tomcat form limit | 2 MB | 500 MB |

### Why Multiple Settings?

1. **Spring Multipart** - Handles file parsing at application level
2. **Tomcat Limits** - HTTP server rejects large requests before Spring sees them
3. **Both needed** - Must configure at all layers to avoid 413 errors

### File Size Display Logic

```typescript
{uploadFile.size > 1024 * 1024 
  ? (uploadFile.size / (1024 * 1024)).toFixed(1) + ' MB'  // Show MB for large files
  : (uploadFile.size / 1024).toFixed(1) + ' KB'           // Show KB for small files
}
```

### Warning Display

```typescript
{uploadFile.size > 500 * 1024 * 1024 && (
  <strong> ⚠️ FILE TOO LARGE!</strong>
)}
```

## Testing

### Small File (< 1 MB)
```
Selected: document.pdf (245.3 KB)
✅ Uploads successfully
```

### Medium File (1 MB - 500 MB)
```
Selected: video.mp4 (125.7 MB)
✅ Uploads successfully (was failing before)
```

### Large File (> 500 MB)
```
Selected: huge-file.zip (678.5 MB) ⚠️ FILE TOO LARGE!
❌ Warning shown, still fails with 413
```

## Upload Flow

1. User selects file
2. UI checks size:
   - < 500 MB → Shows size in KB/MB
   - > 500 MB → Shows size + red warning
3. User clicks "Upload"
4. Spring checks:
   - File size < 500 MB? → Accept
   - File size > 500 MB? → Return 413
5. Tomcat checks:
   - Request size < 500 MB? → Forward to Spring
   - Request size > 500 MB? → Return 413

## Error Messages

### Before Fix
```
POST /api/dms/documents/1164/content
Status: 413 Payload Too Large
Error: Request Entity Too Large
```

### After Fix (file < 500 MB)
```
POST /api/dms/documents/1164/content
Status: 200 OK
Response: { status: "success", contentId: 1234, ... }
```

### After Fix (file > 500 MB)
```
UI Warning: ⚠️ FILE TOO LARGE!
User sees warning before attempting upload
```

## Adjusting the Limit

To change the 500 MB limit to a different size:

1. **Edit `application.yml`**:
```yaml
spring:
  servlet:
    multipart:
      max-file-size: 1GB      # Change here
      max-request-size: 1GB   # And here

server:
  tomcat:
    max-swallow-size: 1GB     # And here
    max-http-form-post-size: 1GB  # And here
```

2. **Edit `DMSPageEnhanced.tsx`**:
```typescript
Maximum file size: 1 GB  // Update display text

{uploadFile.size > 1 * 1024 * 1024 * 1024 && ...}  // Update check (1GB)
```

## Performance Considerations

### Memory Usage

- Files < 2 KB → Kept in memory
- Files > 2 KB → Written to disk (temp directory)
- Large uploads don't consume heap space

### Disk Space

Temporary files stored in system temp directory:
- Linux/Mac: `/tmp`
- Windows: `%TEMP%`

Files cleaned up after upload completes.

### Network Timeouts

For very large files, consider increasing timeouts:

```yaml
spring:
  mvc:
    async:
      request-timeout: 300000  # 5 minutes (default 30 seconds)
```

## Common Issues

### Still Getting 413 After Config?

1. **Restart required** - Configuration changes need server restart
2. **Nginx/Proxy** - If using reverse proxy, check its limits too
3. **Client timeout** - Very large files may timeout on slow connections

### Nginx Configuration (if applicable)
```nginx
client_max_body_size 500M;
proxy_connect_timeout 600;
proxy_send_timeout 600;
proxy_read_timeout 600;
send_timeout 600;
```

## Status

✅ **Upload limit increased to 500 MB**  
✅ **UI shows size limit**  
✅ **File size displayed intelligently (KB/MB)**  
✅ **Warning shown for oversized files**  
✅ **Both Spring and Tomcat configured**  

Backend running at http://localhost:8080 ✅  
Frontend running at http://localhost:3000 ✅

You can now upload files up to **500 MB**!
