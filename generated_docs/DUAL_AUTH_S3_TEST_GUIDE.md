# Dual Authentication S3 Test - Complete Guide

## Overview

The updated **`HitorroS3AbstractionTest`** now demonstrates **BOTH authentication methods** with MinIO:

1. ✅ **Root Username/Password** (admin/mypassword)
2. ✅ **App Token (Access Keys)** created dynamically via `mc` commands

## What It Does

The test automatically:
1. Detects your MinIO Docker container
2. Configures `mc` alias
3. Verifies/creates the bucket
4. **Creates an app token using `mc admin accesskey create`**
5. Runs full test suite with **root credentials**
6. Runs full test suite with **app token credentials**
7. Shows how to clean up the app token

## Quick Start

### 1. Start MinIO

```bash
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=mypassword \
  quay.io/minio/minio server /data --console-address ":9001"
```

### 2. Run the Test

**In IntelliJ:**
```
File: hitorro-util/src/test/java/com/hitorro/util/basefile/fs/s3/HitorroS3AbstractionTest.java
Right-click → Run 'HitorroS3AbstractionTest.main()'
```

**From Command Line:**
```bash
cd hitorro-util
mvn exec:java \
  -Dexec.mainClass="com.hitorro.util.basefile.fs.s3.HitorroS3AbstractionTest" \
  -Dexec.classpathScope=test
```

## Expected Output

```
==============================================================
Hitorro S3 Abstraction Test - Dual Authentication Demo
==============================================================

Step 1: Initializing Hitorro environment...
  ✓ Hitorro environment initialized

Step 2: Detecting MinIO container...
  ✓ MinIO container: a1b2c3d4e5f6

Step 3: Configuring mc alias...
  ✓ mc alias configured

Step 4: Verifying bucket 'test'...
  → Bucket exists
  ✓ Bucket verified

Step 5: Creating app token via mc...
  → mc: Access Key: ABCD1234EFGH5678
  → mc: Secret Key: secretkey12345678901234567890
  ✓ App Access Key: ABCD1234EFGH5678
  ✓ App Secret Key: secretkey...

Test directory: test-run-abc12345
==============================================================

METHOD 1: Testing with ROOT CREDENTIALS
----------------------------------------
Using: admin / mypassword
  Test 1: Write text file... ✓
  Test 2: Check file exists and metadata... ✓
  Test 3: Read file back... ✓
  Test 4: Write multiple files... ✓
  Test 5: Binary data... ✓
  Test 6: Large file (500KB)... ✓
✓ Root credential authentication SUCCESS

METHOD 2: Testing with APP TOKEN
----------------------------------------
Using: ABCD1234EFGH5678 / secretkey...
  Test 1: Write text file... ✓
  Test 2: Check file exists and metadata... ✓
  Test 3: Read file back... ✓
  Test 4: Write multiple files... ✓
  Test 5: Binary data... ✓
  Test 6: Large file (500KB)... ✓
✓ App token authentication SUCCESS

==============================================================
✓ ALL TESTS PASSED WITH BOTH AUTHENTICATION METHODS!
==============================================================

Authentication Methods Demonstrated:
  1. Root username/password: admin / mypassword
  2. App token (access key): ABCD1234EFGH5678

View files in MinIO Console:
  http://localhost:9001/browser/test/test-run-abc12345

Clean up app token:
  docker exec -it a1b2c3d4e5f6 mc admin accesskey rm mylocal ABCD1234EFGH5678
==============================================================
```

## How It Works

### Automatic App Token Creation

The test uses the `mc` command from your comments:

```java
docker exec -it <container_id> mc admin accesskey create mylocal/admin \
  --name hitorro-test-12345678 \
  --description "Hitorro Test App Token" \
  --expiry-duration 24h
```

It then parses the output to extract:
- **Access Key**: e.g., `ABCD1234EFGH5678`
- **Secret Key**: e.g., `secretkey12345678901234567890`

### Test Structure

```java
// METHOD 1: Root credentials
runS3Tests(
    "admin",           // root username
    "mypassword",      // root password
    "test-run-abc/root-auth"
);

// METHOD 2: App token
runS3Tests(
    "ABCD1234EFGH5678",                    // app access key
    "secretkey12345678901234567890",      // app secret key
    "test-run-abc/app-token-auth"
);
```

### What Each Test Does

Both authentication methods run the same 6 tests using **Hitorro's BaseFile API**:

1. **Write text file** - Creates a file with UTF-8 content
2. **Check metadata** - Verifies `exists()` and `length()` methods
3. **Read file back** - Reads content and verifies it matches
4. **Write multiple files** - Batch file operations
5. **Binary data** - Writes and verifies binary data (byte-for-byte)
6. **Large file** - Tests 500KB file (multipart upload)

## Cleanup

The test shows you how to clean up the app token:

```bash
# Get the access key from test output
ACCESS_KEY="ABCD1234EFGH5678"

# Remove it
docker exec -it <container_id> mc admin accesskey rm mylocal $ACCESS_KEY
```

Or list all access keys:

```bash
docker exec -it <container_id> mc admin accesskey ls mylocal/admin
```

## MC Commands Reference

The test automates these `mc` commands:

```bash
# Configure alias (automated)
mc alias set mylocal http://localhost:9000 admin mypassword

# Check bucket (automated)
mc ls mylocal/test

# Create bucket if needed (automated)
mc mb mylocal/test

# Create app token (automated)
mc admin accesskey create mylocal/admin \
  --name hitorro-test-app \
  --description "Hitorro Test App Token" \
  --expiry-duration 24h

# List access keys (manual)
mc admin accesskey ls mylocal/admin

# Remove access key (shown in output for manual cleanup)
mc admin accesskey rm mylocal <ACCESS_KEY>
```

## Code Structure

```java
// Custom Hitorro S3 filesystem for MinIO
class MinioS3FileSystem extends HTS3FileSystem {
    // Configures S3A with MinIO endpoint
    // Uses path-style access
    // Disables SSL for local testing
}

// Main test flow
main() {
    1. Initialize Hitorro environment
    2. Detect MinIO container
    3. Configure mc alias
    4. Verify/create bucket
    5. Create app token via mc
    6. Test with root credentials
    7. Test with app token
    8. Show cleanup instructions
}

// Test runner (called twice)
runS3Tests(accessKey, secretKey, testDirectory) {
    // 6 comprehensive tests using BaseFile API
}
```

## Benefits

✅ **Complete automation** - No manual mc commands needed  
✅ **Both auth methods** - Demonstrates root + app tokens  
✅ **Production patterns** - Shows real-world usage  
✅ **Self-contained** - Creates and uses its own app token  
✅ **Clean** - Shows how to clean up afterward  
✅ **Educational** - Learn mc commands for MinIO admin  

## Troubleshooting

### "MinIO container not found"
Make sure MinIO is running:
```bash
docker ps | grep minio
```

### "Failed to create app token"
Check the mc output in the test logs. Common issues:
- Wrong credentials
- mc not available in container
- Alias not configured

### "Bucket doesn't exist"
The test creates it automatically, but if it fails, create manually:
```bash
docker exec -it <container_id> mc mb mylocal/test
```

## Summary

The updated test **fully automates both authentication methods**:

1. ✅ **Root credentials** - Uses admin/mypassword directly
2. ✅ **App tokens** - Creates via `mc admin accesskey create` command
3. ✅ **6 comprehensive tests** - With each authentication method
4. ✅ **Hitorro BaseFile API** - Complete abstraction layer demonstration
5. ✅ **Production ready** - Shows best practices for both methods

Just **start MinIO and run the test** - it handles everything else! 🎉
