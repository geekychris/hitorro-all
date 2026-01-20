# Hitorro S3 Test - Quick Start Guide

## ✅ Test is Ready!

The `SimpleHitorroS3Test` is compiled and ready to run. It demonstrates the complete Hitorro BaseFile API with S3A and MinIO.

## Prerequisites

### 1. Start MinIO

```bash
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  quay.io/minio/minio server /data --console-address ":9001"
```

### 2. Create Bucket

**Option A: Web Console** (easiest)
1. Open http://localhost:9001
2. Login with minioadmin/minioadmin
3. Click "Create Bucket"
4. Name: `hitorro-test`
5. Click "Create"

**Option B: MC Command Line**
```bash
# Get container ID
docker ps

# Create bucket
docker exec -it <container_id> mc alias set local http://localhost:9000 minioadmin minioadmin
docker exec -it <container_id> mc mb local/hitorro-test
```

## Run the Test

### From IntelliJ (Recommended)

1. Open `SimpleHitorroS3Test.java` in IntelliJ
2. Right-click on the file
3. Select "Run 'SimpleHitorroS3Test.main()'"

### From Maven

```bash
cd hitorro-util
mvn exec:java \
  -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.SimpleHitorroS3Test" \
  -Dexec.classpathScope=test
```

## Expected Output

```
==============================================================
Hitorro S3 Abstraction Test with MinIO
==============================================================

Initializing Hitorro environment...
✓ Hitorro environment initialized

Test directory: test-run-abc12345

✓ Connected to MinIO at http://localhost:9000
✓ Using bucket: hitorro-test

Test 1: Write text file... ✓ PASSED
Test 2: Check file exists and metadata... ✓ PASSED
Test 3: Read file back... ✓ PASSED
Test 4: Write multiple files... ✓ PASSED
Test 5: Binary data... ✓ PASSED
Test 6: Copy file... ✓ PASSED
Test 7: Large file streaming (1MB)... ✓ PASSED
Test 8: Delete operations... ✓ PASSED

==============================================================
Test Summary: 8/8 passed
==============================================================

✓ ALL TESTS PASSED! S3A integration working perfectly.

You can view the test files in MinIO console:
  http://localhost:9001/browser/hitorro-test/test-run-abc12345
```

## What the Test Demonstrates

### 1. **Hitorro BaseFile API**
The recommended abstraction layer that works across S3, HDFS, FTP, and local files:

```java
// Create filesystem
MinioS3FileSystem s3 = new MinioS3FileSystem(endpoint, bucket, secret, key);

// Get file handle
BaseFile file = s3.getFile("path/to/file.txt");

// Write
try (OutputStream os = file.getOutputStream()) {
    os.write("Hello!".getBytes());
}

// Read
try (InputStream is = file.getInputStream()) {
    String content = new String(is.readAllBytes());
}

// Metadata
boolean exists = file.exists();
long size = file.length();
String name = file.getName();

// Delete
file.delete();
```

### 2. **8 Comprehensive Tests**

1. ✅ **Write text file** - UTF-8 text handling
2. ✅ **Check metadata** - exists(), length() methods
3. ✅ **Read file back** - Content verification
4. ✅ **Multiple files** - Batch operations
5. ✅ **Binary data** - Byte-for-byte integrity
6. ✅ **Copy file** - Stream operations
7. ✅ **Large file** - 1MB with streaming (tests multipart upload)
8. ✅ **Delete** - File removal and verification

### 3. **Production-Ready Code**

The test shows real-world patterns:
- Proper stream handling with try-with-resources
- Error handling and assertions
- Performance tuning (connection pooling, multipart uploads)
- MinIO compatibility (path-style access, HTTP)

## Configuration

The test uses these MinIO defaults:
```java
MINIO_ENDPOINT = "http://localhost:9000"
BUCKET_NAME = "hitorro-test"
ACCESS_KEY = "minioadmin"
SECRET_KEY = "minioadmin"
```

To use different credentials, edit the constants at the top of `SimpleHitorroS3Test.java`.

## View Results

After the test runs, view the uploaded files:
- **Web Console**: http://localhost:9001/browser/hitorro-test/
- **Files are in**: `test-run-<random>/` directory

Each test run creates a unique directory so multiple runs don't interfere.

## Troubleshooting

### "Bucket does not exist"
Create the bucket first:
```bash
docker exec -it <container_id> mc mb local/hitorro-test
```

### "Connection refused"
Make sure MinIO is running:
```bash
docker ps | grep minio
```

### "Access denied"
Check credentials match MinIO configuration.

## Next Steps

### Adapt for AWS S3

Change the endpoint configuration:
```java
// Replace MinIO endpoint with AWS region
conf.set("fs.s3a.endpoint.region", "us-east-1");
conf.set("fs.s3a.connection.ssl.enabled", "true");
// Remove path.style.access setting (AWS uses virtual-hosted style)
```

### Use in Production

The `HTS3FileSystem` class is production-ready:
```java
S3Config config = new S3Config();
config.bucket = "my-prod-bucket";
config.accessKey = "AKIA...";
config.secretAccessKey = "secret...";
config.region = "us-east-1";

HTS3FileSystem s3 = config.getFileSystem();
BaseFile file = s3.getFile("documents/report.pdf");
// Use file just like any other BaseFile!
```

## Summary

✅ **Test compiled successfully**  
✅ **8 comprehensive test scenarios**  
✅ **Production-ready examples**  
✅ **Complete BaseFile API coverage**  
✅ **Ready to run with MinIO**  

Just **start MinIO, create the bucket, and run the test**! 🎉
