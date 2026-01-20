# S3 Test Suite - Complete Guide

## Overview

Two comprehensive tests demonstrate the S3A upgrade with MinIO:

1. **`SimpleMinioS3Test`** - Direct Hadoop FileSystem API (low-level)
2. **`HitorroS3AbstractionTest`** - Hitorro BaseFile API (abstraction layer) ⭐

## Test 1: SimpleMinioS3Test (Low-Level)

**File**: `hitorro-util/src/test/java/com/hitorro/util/basefile/fs/s3/SimpleMinioS3Test.java`

### What It Tests
- Direct use of Hadoop FileSystem API
- S3A configuration with MinIO
- FSDataInputStream / FSDataOutputStream
- FileStatus operations
- Raw performance benchmarks

### Usage
```bash
mvn exec:java \
  -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.SimpleMinioS3Test" \
  -Dexec.classpathScope=test
```

### Key APIs Demonstrated
```java
FileSystem fs = FileSystem.get(uri, conf);
FSDataOutputStream out = fs.create(path);
FSDataInputStream in = fs.open(path);
FileStatus[] files = fs.listStatus(dir);
```

## Test 2: HitorroS3AbstractionTest (High-Level) ⭐

**File**: `hitorro-util/src/test/java/com/hitorro/util/basefile/fs/s3/HitorroS3AbstractionTest.java`

### What It Tests
- **Hitorro's BaseFile abstraction** (the way you should use it!)
- Unified API across S3, HDFS, FTP, local files
- HTS3FileSystem with MinIO
- S3Config usage
- File operations through BaseFile interface

### Usage
```bash
mvn exec:java \
  -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.HitorroS3AbstractionTest" \
  -Dexec.classpathScope=test
```

### Key APIs Demonstrated

#### 1. Creating S3 FileSystem
```java
// Using HTS3FileSystem (Hitorro abstraction)
HTS3FileSystem s3fs = new HTS3FileSystem(bucketName, secretKey, accessKey);

// Or using S3Config
S3Config config = new S3Config();
config.bucket = "my-bucket";
config.accessKey = "...";
config.secretAccessKey = "...";
HTS3FileSystem s3fs = config.getFileSystem();
```

#### 2. Getting Files (BaseFile)
```java
// Get a file handle
BaseFile file = s3fs.getFile("path/to/file.txt");

// Get file ensuring directory exists
BaseFile file = s3fs.getFileEnsuringDir("deep/nested/path/file.txt");
```

#### 3. Writing Files
```java
// Write text
try (OutputStream os = file.getOutputStream()) {
    os.write("Hello S3!".getBytes());
}

// Write binary
byte[] data = new byte[1024];
try (OutputStream os = file.getOutputStream()) {
    os.write(data);
}
```

#### 4. Reading Files
```java
// Read text
try (InputStream is = file.getInputStream()) {
    String content = new String(is.readAllBytes());
}

// Read binary
try (InputStream is = file.getInputStream()) {
    byte[] data = is.readAllBytes();
}
```

#### 5. File Operations
```java
// Check exists
boolean exists = file.exists();

// Get size
long size = file.length();

// Get name
String name = file.getName();

// Get path
String path = file.getRelativePath();

// Delete
boolean deleted = file.delete();
```

#### 6. Directory Operations
```java
// List files
BaseFile dir = s3fs.getFile("mydir");
BaseFile[] files = dir.listFiles();

for (BaseFile f : files) {
    System.out.println(f.getName() + ": " + f.length() + " bytes");
}
```

#### 7. Copying Files
```java
BaseFile source = s3fs.getFile("source.txt");
BaseFile dest = s3fs.getFile("dest.txt");

try (InputStream is = source.getInputStream();
     OutputStream os = dest.getOutputStream()) {
    is.transferTo(os);
}
```

### Tests Included

| Test | Description | What It Shows |
|------|-------------|---------------|
| Test 1 | Write text file | Basic file creation |
| Test 2 | Check file exists | File metadata operations |
| Test 3 | Read file back | Reading and verification |
| Test 4 | Write multiple files | Batch operations |
| Test 5 | List directory | Directory traversal |
| Test 6 | Copy file | Stream copying |
| Test 7 | Binary data | Non-text data handling |
| Test 8 | Nested paths | getFileEnsuringDir |
| Test 9 | Large file (2MB) | Streaming, performance |
| Test 10 | Delete file | Cleanup operations |
| Test 11 | S3Config | Configuration objects |

## Prerequisites

### 1. Start MinIO
```bash
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  quay.io/minio/minio server /data --console-address ":9001"
```

### 2. Create Bucket
1. Open: http://localhost:9001
2. Login: minioadmin / minioadmin
3. Create bucket: `test`

### 3. Create Access Keys
1. Go to Access Keys
2. Create new key
3. Use the provided credentials in the test

**Current test credentials:**
- Access Key: `4N82TRBS71UDJRPZOB4X`
- Secret Key: `XbrHwzzrzkAeMMGHw6+m+E9HM2z24lUPr7c32gBY`

## Expected Output - HitorroS3AbstractionTest

```
========================================
Hitorro S3 Abstraction Test
(Using BaseFile API)
========================================
Endpoint: http://localhost:9000
Bucket:   test
========================================

Test directory: hitorro-test-abc12345

Creating Hitorro S3 FileSystem...
✓ S3 FileSystem created and available

Test 1: Writing file using BaseFile API...
  File type: DFSFile
  ✓ Written 62 bytes
  ✓ File path: hitorro-test-abc12345/hello.txt

Test 2: Checking file exists...
  ✓ File exists: true
  ✓ File size: 62 bytes

Test 3: Reading file using BaseFile API...
  ✓ Read 62 bytes
  Content matches: true

Test 4: Writing multiple files...
  ✓ Written file-1.txt (62 bytes)
  ✓ Written file-2.txt (112 bytes)
  ✓ Written file-3.txt (162 bytes)
  ✓ Written file-4.txt (212 bytes)
  ✓ Written file-5.txt (262 bytes)

Test 5: Listing directory using BaseFile API...
  ✓ Directory listing (items may be in subdirectories)

Test 6: Copying file using BaseFile API...
  ✓ Copied 62 bytes
  ✓ Destination file exists: true

Test 7: Writing binary data using BaseFile API...
  ✓ Written 2048 bytes of binary data
  ✓ Binary data verified: true

Test 8: Using getFileEnsuringDir...
  ✓ Created nested file: hitorro-test-abc12345/nested/deep/path/file.txt
  ✓ File exists: true

Test 9: Streaming large file (2MB)...
  Progress: 0KB written
  Progress: 256KB written
  Progress: 512KB written
  Progress: 768KB written
  Progress: 1024KB written
  Progress: 1280KB written
  Progress: 1536KB written
  Progress: 1792KB written
  ✓ Written 2MB in 1234ms
  ✓ Throughput: 1.66 MB/s

Test 10: Deleting file using BaseFile API...
  ✓ Created temp file
  ✓ Delete successful: true
  ✓ File exists after delete: false

Test 11: Using S3Config for filesystem creation...
  ✓ Created S3Config
    Bucket: test
    Access Key: 4N82T...

========================================
✓ All Hitorro BaseFile API tests passed!
========================================

Key Features Demonstrated:
  ✓ BaseFile abstraction (unified API)
  ✓ Read/Write operations
  ✓ File operations (exists, length, delete)
  ✓ Directory operations (listFiles)
  ✓ Binary and text data
  ✓ Streaming large files
  ✓ Nested paths with getFileEnsuringDir
  ✓ File copying
  ✓ S3Config usage

View files in MinIO Console:
  http://localhost:9001/browser/test/hitorro-test-abc12345

Note: Test files left in MinIO for inspection.
========================================
```

## Comparison: Which Test to Use?

### Use SimpleMinioS3Test When:
- Testing low-level Hadoop FileSystem behavior
- Benchmarking raw S3A performance
- Debugging S3A configuration issues
- Working directly with Hadoop APIs

### Use HitorroS3AbstractionTest When: ⭐
- **Using Hitorro's BaseFile API** (recommended!)
- Writing application code
- Need unified API across storage types
- Want to switch between S3/HDFS/FTP/local transparently
- Building on Hitorro abstractions

## Integration Example

Here's how you'd use this in real code:

```java
// Configure S3 filesystem
S3Config config = new S3Config();
config.bucket = "my-app-data";
config.accessKey = System.getenv("AWS_ACCESS_KEY");
config.secretAccessKey = System.getenv("AWS_SECRET_KEY");
config.region = "us-east-1";

HTS3FileSystem s3 = config.getFileSystem();

// Store document
BaseFile docFile = s3.getFile("documents/report-2024.pdf");
try (InputStream source = new FileInputStream("report.pdf");
     OutputStream dest = docFile.getOutputStream()) {
    source.transferTo(dest);
}
System.out.println("Stored: " + docFile.getRelativePath());

// Retrieve document
BaseFile storedDoc = s3.getFile("documents/report-2024.pdf");
if (storedDoc.exists()) {
    try (InputStream is = storedDoc.getInputStream();
         OutputStream os = new FileOutputStream("downloaded.pdf")) {
        is.transferTo(os);
    }
}

// List all documents
BaseFile docsDir = s3.getFile("documents");
BaseFile[] documents = docsDir.listFiles();
for (BaseFile doc : documents) {
    System.out.println("- " + doc.getName() + " (" + doc.length() + " bytes)");
}
```

## Benefits of Hitorro Abstraction

### 1. Unified API
Same code works for S3, HDFS, FTP, local files:
```java
// Just change the FileSystem implementation
BaseFileSystem fs = new HTS3FileSystem(...);      // S3
// BaseFileSystem fs = new DFSFileSystem(...);    // HDFS
// BaseFileSystem fs = new FileFileSystem(...);   // Local
// BaseFileSystem fs = new FTPFileSystem(...);    // FTP

BaseFile file = fs.getFile("myfile.txt");
// Same operations regardless of storage!
```

### 2. Easy Migration
Move data between storage types without code changes:
```java
// Copy from local to S3
FileFileSystem local = new FileFileSystem(new File("/data"));
HTS3FileSystem s3 = new HTS3FileSystem("bucket", secret, key);

BaseFile localFile = local.getFile("important.dat");
BaseFile s3File = s3.getFile("backup/important.dat");

try (InputStream is = localFile.getInputStream();
     OutputStream os = s3File.getOutputStream()) {
    is.transferTo(os);
}
```

### 3. DMS Integration
Works seamlessly with Hitorro DMS:
```java
// Store DMS content in S3
Document doc = dmsSession.newDocument();
doc.setObjectName("My Document");

Content content = doc.newContent();
BaseFile s3File = s3.getFile("documents/doc-123.pdf");
content.setFile(s3File);  // Store content in S3!

doc.save();
```

## Running Tests

### Compile
```bash
cd hitorro-util
mvn test-compile
```

### Run SimpleMinioS3Test
```bash
mvn exec:java \
  -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.SimpleMinioS3Test" \
  -Dexec.classpathScope=test
```

### Run HitorroS3AbstractionTest ⭐
```bash
mvn exec:java \
  -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.HitorroS3AbstractionTest" \
  -Dexec.classpathScope=test
```

### Run Both
```bash
# Run SimpleMinioS3Test
mvn exec:java -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.SimpleMinioS3Test" -Dexec.classpathScope=test

# Run HitorroS3AbstractionTest
mvn exec:java -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.HitorroS3AbstractionTest" -Dexec.classpathScope=test
```

## Troubleshooting

### Connection Refused
**Cause**: MinIO not running  
**Solution**: Start MinIO with docker command above

### Access Denied
**Cause**: Invalid credentials or missing bucket  
**Solution**: Verify bucket exists, check credentials

### ClassNotFoundException
**Cause**: Missing dependencies  
**Solution**: `mvn clean install` to rebuild

### File Not Found in listFiles()
**Cause**: S3 "folders" are virtual  
**Solution**: Files in subdirectories won't show in parent listing - this is expected S3 behavior

## Next Steps

1. ✅ Run both tests with MinIO
2. ✅ Inspect files in MinIO Console
3. ✅ Try modifying tests for your use case
4. ✅ Integrate BaseFile API into your application
5. ✅ Test with real AWS S3 (just change endpoint config)

## Summary

✅ **Two comprehensive tests** demonstrate S3A with MinIO  
✅ **Low-level test** shows Hadoop FileSystem API  
✅ **High-level test** shows Hitorro BaseFile abstraction ⭐  
✅ **11 test cases** cover all common operations  
✅ **Production-ready** examples you can copy  
✅ **Works with MinIO** and AWS S3  

The **HitorroS3AbstractionTest is the recommended approach** for application development - it provides a clean, unified API and makes your code portable across storage backends! 🎉
