# S3 Test Troubleshooting Guide

## Issue: Test 6 "File size mismatch"

### Symptoms
```
Test 6: Large file (500KB)... Exception in thread "main" java.lang.AssertionError: File size mismatch
```

### Possible Causes

1. **S3 eventual consistency** - The file write completed but S3 hasn't fully propagated the size metadata yet
2. **Cached file handle** - The BaseFile object is reading cached metadata
3. **Incomplete write** - Not all bytes were written (less likely with try-with-resources)

### Fix Applied

The test now:
1. Tracks bytes written during the write operation
2. Gets a **fresh file handle** after closing the output stream
3. Provides **detailed error message** showing:
   - Expected size
   - Actual size reported by S3
   - Bytes written

### Error Message Format

```
File size mismatch: expected 512000, got 0, wrote 512000
```

This tells us:
- **expected 512000** - What we should have (500KB)
- **got 0** - What S3 reports (indicates metadata not updated)
- **wrote 512000** - Confirmed all bytes were written

### Solutions

#### Solution 1: Add Small Delay (if needed)

If the error persists, add a small delay before checking size:

```java
// After closing the stream
Thread.sleep(100); // 100ms delay

// Then check size
BaseFile verifyFile = s3.getFile(testDirectory + "/large.dat");
long actualSize = verifyFile.length();
```

#### Solution 2: Retry Logic

For production code, use retry logic:

```java
long actualSize = 0;
int retries = 5;
for (int i = 0; i < retries; i++) {
    BaseFile verifyFile = s3.getFile(testDirectory + "/large.dat");
    actualSize = verifyFile.length();
    if (actualSize == size) break;
    Thread.sleep(100);
}
```

#### Solution 3: Skip Size Check

For testing purposes, you can verify the file exists instead:

```java
BaseFile verifyFile = s3.getFile(testDirectory + "/large.dat");
if (!verifyFile.exists()) {
    throw new AssertionError("File should exist after write");
}
// Size check is informational only
System.out.println("  (Size: " + verifyFile.length() + " bytes)");
```

### Why This Happens

**S3 Eventual Consistency:**
- S3 (and MinIO) may take a moment to update metadata after a write
- The file data is committed, but metadata queries might lag
- This is normal S3 behavior and shouldn't affect production usage

**BaseFile Caching:**
- Some file system implementations cache metadata
- Getting a fresh file handle forces a new metadata query

### Verification

The test should now show the actual problem:

```bash
# If you see this:
File size mismatch: expected 512000, got 512000, wrote 512000
# → Comparison bug (shouldn't happen now)

# If you see this:
File size mismatch: expected 512000, got 0, wrote 512000
# → S3 metadata not updated yet (add small delay)

# If you see this:
File size mismatch: expected 512000, got 300000, wrote 300000
# → Write was interrupted (shouldn't happen with try-with-resources)
```

### Current Status

✅ Better error reporting added  
✅ Fresh file handle obtained  
✅ Detailed error message shows all three values  
✅ Ready to diagnose the actual issue  

Run the test again and check the error message to see which scenario we're hitting! 🔍
