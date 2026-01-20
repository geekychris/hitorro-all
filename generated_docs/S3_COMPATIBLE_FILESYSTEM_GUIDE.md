# S3CompatibleFileSystem - Complete Guide

## Overview

**`S3CompatibleFileSystem`** is a production-ready class for connecting to any S3-compatible service using Hitorro's BaseFile abstraction.

**Moved from test code to main source** for general use! 🎉

## Location

```
hitorro-util/src/main/java/com/hitorro/util/basefile/fs/s3/S3CompatibleFileSystem.java
```

## Supported Services

✅ **MinIO** - Self-hosted object storage  
✅ **Wasabi** - Fast cloud storage  
✅ **DigitalOcean Spaces** - Simple cloud storage  
✅ **Backblaze B2** - S3-compatible API  
✅ **Cloudflare R2** - Zero-egress storage  
✅ **Any S3-compatible service**  

## Usage Examples

### MinIO (Local Development)

```java
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(
    "http://localhost:9000",  // endpoint
    "my-bucket",              // bucket
    "minioadmin",             // access key
    "minioadmin",             // secret key
    false                     // SSL disabled
);

BaseFile file = s3.getFile("documents/report.pdf");
try (OutputStream os = file.getOutputStream()) {
    os.write(pdfData);
}
```

### Wasabi (Production)

```java
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(
    "https://s3.us-east-2.wasabisys.com",
    "my-bucket",
    "AKIAIOSFODNN7EXAMPLE",
    "wJalrXUtnFEMI/K7MDENG/bPxRfiCY...",
    true  // SSL enabled
);

BaseFile file = s3.getFile("backups/data.zip");
if (file.exists()) {
    long size = file.length();
    System.out.println("Backup size: " + size);
}
```

### DigitalOcean Spaces

```java
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(
    "https://nyc3.digitaloceanspaces.com",
    "my-space",
    "DO00EXAMPLE",
    "secret...",
    true
);

// List all files
BaseFile root = s3.getFile("/");
for (BaseFile file : root.listFiles()) {
    System.out.println(file.getName());
}
```

### Cloudflare R2

```java
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(
    "https://<account-id>.r2.cloudflarestorage.com",
    "my-bucket",
    "access-key",
    "secret-key",
    true
);
```

## Configuration Customization

Override `configureFileSystem()` for service-specific tuning:

```java
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(
    "https://s3.wasabisys.com",
    "my-bucket",
    "access-key",
    "secret-key",
    true
) {
    @Override
    protected void configureFileSystem(Configuration conf) {
        super.configureFileSystem(conf);
        
        // Custom settings for Wasabi
        conf.set("fs.s3a.connection.maximum", "100");
        conf.set("fs.s3a.threads.max", "64");
        conf.set("fs.s3a.multipart.size", "104857600"); // 100MB
        
        // Wasabi-specific region
        conf.set("fs.s3a.endpoint.region", "us-east-2");
    }
};
```

## Default Configuration

The class provides sensible defaults:

```java
fs.s3a.connection.maximum = 50           // Connection pool size
fs.s3a.threads.max = 32                  // Max threads
fs.s3a.multipart.size = 52428800         // 50MB chunks
fs.s3a.fast.upload.buffer = bytebuffer   // Fast uploads
fs.s3a.attempts.maximum = 10             // Retry attempts
fs.s3a.retry.limit = 5                   // Retry limit
fs.s3a.path.style.access = true          // Required for most S3-compatible
```

## Complete BaseFile API

Works with all BaseFile operations:

### Read/Write

```java
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(...);

// Write
BaseFile file = s3.getFile("data/file.txt");
try (OutputStream os = file.getOutputStream()) {
    os.write("Hello World!".getBytes());
}

// Read
try (InputStream is = file.getInputStream()) {
    String content = new String(is.readAllBytes());
}
```

### Metadata

```java
BaseFile file = s3.getFile("data/file.txt");

boolean exists = file.exists();
long size = file.length();
String name = file.getName();
String path = file.getPath();
```

### Directory Operations

```java
BaseFile dir = s3.getFile("my-directory");

// List files
BaseFile[] files = dir.listFiles();

// Create directory
BaseFile newDir = s3.getFile("new-directory");
newDir.mkdir();
```

### Delete

```java
BaseFile file = s3.getFile("temp/old-file.txt");
boolean deleted = file.delete();
```

### Copy/Move

```java
BaseFile src = s3.getFile("source.txt");
BaseFile dst = s3.getFile("destination.txt");

try (InputStream is = src.getInputStream();
     OutputStream os = dst.getOutputStream()) {
    is.transferTo(os);
}
```

## vs HTS3FileSystem

| Feature | HTS3FileSystem | S3CompatibleFileSystem |
|---------|---------------|------------------------|
| **AWS S3** | ✅ Best choice | ✅ Works |
| **MinIO** | ❌ Needs custom endpoint | ✅ Built-in |
| **Wasabi** | ❌ Needs custom endpoint | ✅ Built-in |
| **Custom endpoint** | ❌ Not supported | ✅ Required parameter |
| **Path-style access** | ❌ Not default | ✅ Enabled by default |
| **SSL control** | ✅ Always enabled | ✅ Configurable |
| **Local dev** | ❌ Difficult | ✅ Easy (HTTP support) |

**Recommendation:**
- Use **`HTS3FileSystem`** for AWS S3
- Use **`S3CompatibleFileSystem`** for everything else

## Migration from Test Code

**Old (test-only):**
```java
MinioS3FileSystem s3 = new MinioS3FileSystem(
    endpoint, bucket, secretKey, accessKey
);
```

**New (production-ready):**
```java
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(
    endpoint, bucket, accessKey, secretKey, sslEnabled
);
```

Note the parameter order changed to be more intuitive!

## Integration with S3Config

```java
// Load config
S3Config config = new S3Config();
config.bucket = "my-bucket";
config.accessKey = "AKIAIOSFODNN7EXAMPLE";
config.secretAccessKey = "secret...";

// Use with S3CompatibleFileSystem
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(
    "https://s3.wasabisys.com",  // endpoint
    config.bucket,
    config.accessKey,
    config.secretAccessKey,
    true
);
```

## Service-Specific Endpoints

### MinIO
```
http://localhost:9000  (local)
https://play.min.io    (demo server)
```

### Wasabi
```
https://s3.us-east-1.wasabisys.com
https://s3.us-east-2.wasabisys.com
https://s3.us-west-1.wasabisys.com
https://s3.eu-central-1.wasabisys.com
```

### DigitalOcean Spaces
```
https://nyc3.digitaloceanspaces.com
https://sfo3.digitaloceanspaces.com
https://sgp1.digitaloceanspaces.com
```

### Backblaze B2
```
https://s3.us-west-000.backblazeb2.com
https://s3.us-west-001.backblazeb2.com
```

### Cloudflare R2
```
https://<account-id>.r2.cloudflarestorage.com
```

## Testing

The test suite uses `S3CompatibleFileSystem`:

```java
// From HitorroS3AbstractionTest.java
S3CompatibleFileSystem s3 = new S3CompatibleFileSystem(
    "http://localhost:9000",  // MinIO local
    "test",                   // bucket
    "admin",                  // access key
    "mypassword",             // secret key
    false                     // HTTP for local
);

// Run comprehensive tests
runS3Tests(s3, "test-directory");
```

## Benefits

✅ **Production-ready** - Moved to main source tree  
✅ **Well-documented** - Comprehensive Javadoc  
✅ **Flexible** - Override methods for customization  
✅ **Battle-tested** - Used in test suite  
✅ **Universal** - Works with any S3-compatible service  
✅ **BaseFile API** - Portable across storage backends  

## Summary

`S3CompatibleFileSystem` is now a **first-class citizen** in Hitorro's file system abstraction layer, ready for production use with any S3-compatible service! 🎉

**Location**: `com.hitorro.util.basefile.fs.s3.S3CompatibleFileSystem`
