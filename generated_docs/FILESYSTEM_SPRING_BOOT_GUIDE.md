# Hitorro File Systems in Spring Boot - Complete Guide

## Overview

Hitorro's abstract file system layer is now integrated with Spring Boot, providing:
- ✅ **Auto-configuration** for file systems
- ✅ **Dependency injection** of file system beans
- ✅ **Unified API** across storage types
- ✅ **Configuration via application.yml**

## Supported File Systems

### Currently Available
1. ✅ **Local File System** - Access to local files and directories

### Coming Soon
2. ⏳ **JAR File System** - Files embedded in JAR archives (commented out)
3. ⏳ **S3-Compatible** - MinIO, Wasabi, DigitalOcean Spaces (commented out)

## Configuration

### application.yml

```yaml
hitorro:
  filesystem:
    # Local file system
    local:
      enabled: true
      base-path: ./data/files  # Base directory for file operations
    
    # JAR file system (commented out - not yet implemented)
    # jar:
    #   enabled: true
    #   jar-path: ./resources.jar
    
    # S3-compatible (commented out - requires additional setup)
    # s3:
    #   enabled: true
    #   endpoint: http://localhost:9000  # MinIO local
    #   bucket: my-bucket
    #   access-key: minioadmin
    #   secret-key: minioadmin
    #   ssl-enabled: false
```

## Using File Systems in Your Code

### 1. Inject File System Bean

```java
@RestController
public class MyController {
    
    @Autowired(required = false)
    private FileFileSystem localFileSystem;
    
    // S3 when available:
    // @Autowired(required = false)
    // private S3CompatibleFileSystem s3FileSystem;
}
```

### 2. Use BaseFile API

```java
// Get a file
BaseFile file = localFileSystem.getFile("documents/report.pdf");

// Write
try (OutputStream os = file.getOutputStream()) {
    os.write(data);
}

// Read
try (InputStream is = file.getInputStream()) {
    byte[] data = is.readAllBytes();
}

// Check existence
boolean exists = file.exists();
long size = file.length();

// List directory
BaseFile dir = localFileSystem.getFile("documents");
BaseFile[] files = dir.listFiles();

// Delete
file.delete();
```

## Example Controller

The example app includes `FileSystemExampleController` with REST endpoints:

### Check Status
```bash
GET /api/filesystem/status
# Returns which file systems are configured
```

### List Files
```bash
GET /api/filesystem/local/list?path=/
# Returns list of files in local filesystem
```

### Read File
```bash
GET /api/filesystem/local/read/test.txt
# Returns file content as text
```

### Write File
```bash
POST /api/filesystem/local/write
Content-Type: application/json

{
  "path": "test/example.txt",
  "content": "Hello World!"
}
```

## Architecture

### Auto-Configuration

```
FileSystemAutoConfiguration
  ├─ localFileSystem bean (FileFileSystem)
  ├─ jarFileSystem bean (commented out)
  └─ s3FileSystem bean (commented out)
```

### Properties

```
FileSystemProperties
  ├─ LocalFileSystemConfig
  ├─ JarFileSystemConfig
  └─ S3FileSystemConfig
```

### Registration

Registered in `META-INF/spring.factories`:
```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.hitorro.spring.autoconfigure.filesystem.FileSystemAutoConfiguration
```

## BaseFile API Reference

### File Operations
- `getOutputStream()` - Write to file
- `getInputStream()` - Read from file
- `exists()` - Check if file exists
- `length()` - Get file size
- `delete()` - Delete file
- `toString()` - Get file path string

### Directory Operations
- `listFiles()` - List files in directory (returns BaseFile[])
- `mkdir()` - Create directory

### Advanced
- `copy(BaseFile dest)` - Copy file
- `move(BaseFile dest)` - Move file

## Future Enhancements

### JAR File System

Once implemented, will provide:
```java
@Autowired(required = false)
private JarFileSystem jarFileSystem;

// Read files from JAR
BaseFile file = jarFileSystem.getFile("config/settings.properties");
String content = IOUtils.toString(file.getInputStream());
```

### S3-Compatible File System

Once dependencies are added:
```java
@Autowired(required = false)
private S3CompatibleFileSystem s3FileSystem;

// Same API works for S3!
BaseFile file = s3FileSystem.getFile("backups/data.zip");
try (OutputStream os = file.getOutputStream()) {
    os.write(backupData);
}
```

## Benefits

✅ **Portable** - Same code works across file systems  
✅ **Injectable** - Fully integrated with Spring DI  
✅ **Configurable** - All settings in application.yml  
✅ **Type-safe** - Strong typing with BaseFile  
✅ **RESTful** - Easy to expose via REST APIs  

## Testing

```java
@SpringBootTest
public class FileSystemTest {
    
    @Autowired
    private FileFileSystem localFileSystem;
    
    @Test
    public void testFileOperations() {
        BaseFile file = localFileSystem.getFile("test.txt");
        
        // Write
        try (OutputStream os = file.getOutputStream()) {
            os.write("test".getBytes());
        }
        
        // Verify
        assertTrue(file.exists());
        assertEquals(4, file.length());
        
        // Clean up
        file.delete();
    }
}
```

## Migration from Direct FileSystem Usage

### Before (Manual)
```java
File baseDir = new File("/data");
FileFileSystem fs = new FileFileSystem(baseDir);
BaseFile file = fs.getFile("test.txt");
```

### After (Spring Boot)
```java
@Autowired
private FileFileSystem localFileSystem;  // Injected!

BaseFile file = localFileSystem.getFile("test.txt");
```

## Summary

Hitorro's file system abstraction is now **Spring Boot native**, providing:
- Auto-configuration
- Dependency injection
- YAML configuration  
- REST API integration
- Portable code across storage backends

**Currently available**: Local file system  
**Coming soon**: JAR and S3-compatible file systems  

The foundation is in place for a complete, Spring-native file storage solution! 🎉
