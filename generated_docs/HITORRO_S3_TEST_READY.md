# Hitorro S3 Test - Ready to Run! ✅

## Quick Start

The test is now fixed and ready to run with your MinIO setup!

### Step 1: Start MinIO (if not already running)

```bash
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  quay.io/minio/minio server /data --console-address ":9001"
```

### Step 2: Verify Bucket Exists

Open: http://localhost:9001  
Login: minioadmin / minioadmin  
Ensure bucket `test` exists

### Step 3: Run the Test

**From IntelliJ/IDE:**
1. Open `HitorroS3AbstractionTest.java`
2. Right-click on the file
3. Select **"Run 'HitorroS3AbstractionTest.main()'"**

**From Maven:**
```bash
cd hitorro-util
mvn exec:java \
  -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.HitorroS3AbstractionTest" \
  -Dexec.classpathScope=test
```

## What Was Fixed

### Issue
`ExceptionInInitializerError` because `JVSProperties` wasn't initialized.

### Solution
Added `initializeHitorroEnvironment()` method that:
1. Creates JVS properties object
2. Sets up system properties (HT_BIN, HT_HOME, temp dir)
3. Initializes JVSProperties before using BaseFileSystem

### Key Code
```java
private static void initializeHitorroEnvironment() {
    JVS props = new JVS();
    
    Map<String, String> systemProps = new HashMap<>();
    systemProps.put("HT_BIN", System.getProperty("user.home") + "/hitorro");
    systemProps.put("HT_HOME", System.getProperty("user.home") + "/hthome");
    
    props.addMap(systemProps);
    JVSProperties.setDefaultProperties(props, false);
}
```

## Expected Output

```
========================================
Hitorro S3 Abstraction Test
(Using BaseFile API)
========================================
Endpoint: http://localhost:9000
Bucket:   test
========================================

Test directory: hitorro-test-abc12345

Initializing Hitorro environment...
✓ Hitorro environment initialized

Creating Hitorro S3 FileSystem...
✓ S3 FileSystem created and available

Test 1: Writing file using BaseFile API...
  File type: DFSFile
  ✓ Written 62 bytes
  ✓ File path: hitorro-test-abc12345/hello.txt

Test 2: Checking file exists...
  ✓ File exists: true
  ✓ File size: 62 bytes

... (9 more tests) ...

========================================
✓ All Hitorro BaseFile API tests passed!
========================================

View files in MinIO Console:
  http://localhost:9001/browser/test/hitorro-test-abc12345
```

## What Gets Tested

1. ✅ **BaseFile API** - Hitorro's abstraction layer
2. ✅ **Write operations** - Text and binary data
3. ✅ **Read operations** - Full content verification
4. ✅ **File metadata** - exists(), length(), getName()
5. ✅ **Directory operations** - listFiles()
6. ✅ **File copying** - Stream-based operations
7. ✅ **Nested paths** - getFileEnsuringDir()
8. ✅ **Large files** - 2MB streaming
9. ✅ **Delete operations** - Cleanup
10. ✅ **S3Config** - Configuration objects

## Your MinIO Credentials

The test is pre-configured with your credentials:
```java
MINIO_ENDPOINT = "http://localhost:9000"
BUCKET_NAME = "test"
ACCESS_KEY = "4N82TRBS71UDJRPZOB4X"
SECRET_KEY = "XbrHwzzrzkAeMMGHw6+m+E9HM2z24lUPr7c32gBY"
```

## View Results

After running the test, view files in MinIO Console:
- Open: http://localhost:9001
- Navigate to: Buckets → test → hitorro-test-[random-id]
- See all files created by the test

## Key Hitorro APIs Used

### Get FileSystem
```java
HTS3FileSystem s3 = new HTS3FileSystem(bucket, secret, key);
```

### Get File
```java
BaseFile file = s3.getFile("path/to/file.txt");
```

### Write
```java
try (OutputStream os = file.getOutputStream()) {
    os.write("Hello S3!".getBytes());
}
```

### Read
```java
try (InputStream is = file.getInputStream()) {
    String content = new String(is.readAllBytes());
}
```

### Check Exists
```java
boolean exists = file.exists();
long size = file.length();
String name = file.getName();
```

### List Directory
```java
BaseFile dir = s3.getFile("mydir");
BaseFile[] files = dir.listFiles();
```

### Delete
```java
boolean deleted = file.delete();
```

## Troubleshooting

### MinIO Connection Refused
**Solution**: Make sure MinIO is running:
```bash
docker ps | grep minio
```

### Bucket Not Found
**Solution**: Create bucket 'test' in MinIO Console (http://localhost:9001)

### Access Denied
**Solution**: Verify access keys match in MinIO Console → Access Keys

### Still Getting JVS Errors
**Solution**: The test now initializes JVS automatically - make sure you're running the latest version

## Next Steps

1. ✅ **Run the test** to verify S3A works with MinIO
2. ✅ **Inspect files** in MinIO Console
3. ✅ **Copy examples** for your application code
4. ✅ **Adapt for AWS S3** by changing endpoint configuration

## Complete Example for Your Code

```java
// Initialize environment (do once at startup)
private static void initializeHitorro() {
    JVS props = new JVS();
    Map<String, String> systemProps = new HashMap<>();
    systemProps.put("HT_BIN", "/path/to/hitorro");
    systemProps.put("HT_HOME", "/path/to/hthome");
    props.addMap(systemProps);
    JVSProperties.setDefaultProperties(props, false);
}

// Use S3 filesystem
public void storeDocument(InputStream docStream, String filename) {
    // Configure S3
    S3Config config = new S3Config();
    config.bucket = "my-documents";
    config.accessKey = System.getenv("AWS_ACCESS_KEY");
    config.secretAccessKey = System.getenv("AWS_SECRET_KEY");
    config.region = "us-east-1";
    
    HTS3FileSystem s3 = config.getFileSystem();
    
    // Store file
    BaseFile file = s3.getFile("documents/" + filename);
    try (OutputStream os = file.getOutputStream()) {
        docStream.transferTo(os);
    }
    
    System.out.println("Stored: " + file.getRelativePath());
}
```

## Files

- **Test**: `hitorro-util/src/test/java/.../HitorroS3AbstractionTest.java`
- **Guide**: `S3_TEST_SUITE_COMPLETE.md`
- **Implementation**: `hitorro-util/src/main/java/.../HTS3FileSystem.java`

## Status

✅ **Compiled** - No errors  
✅ **Ready to run** - Just needs MinIO running  
✅ **Complete tests** - 11 test scenarios  
✅ **JVS initialized** - Environment setup automated  
✅ **Production examples** - Copy/paste ready code  

The test is **ready to go** - just run it and watch it demonstrate the complete S3A integration! 🎉
