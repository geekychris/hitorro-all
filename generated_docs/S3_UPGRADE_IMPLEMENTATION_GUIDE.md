# S3 FileSystem Upgrade - Implementation Guide

## Quick Reference

**Goal**: Update Hitorro S3 support from JetS3t 0.9.4 to modern S3A with AWS SDK v2  
**Approach**: Upgrade existing DFSFileSystem/HTS3FileSystem  
**Timeline**: 2-3 days development + 1-2 days testing  
**Risk Level**: Medium (mitigated by backward compatibility)

## Prerequisites

- [ ] Read `S3_FILESYSTEM_MODERNIZATION_ANALYSIS.md`
- [ ] Backup existing S3 configuration
- [ ] Identify all current S3 usage in codebase
- [ ] Set up test S3 bucket for validation

## Step 1: Update Dependencies

### Remove Old Dependencies

**File**: `hitorro-basedms/pom.xml`

```xml
<!-- REMOVE THIS -->
<dependency>
    <groupId>net.java.dev.jets3t</groupId>
    <artifactId>jets3t</artifactId>
    <version>0.9.4</version>
</dependency>
```

### Add New Dependencies

**File**: `hitorro-basedms/pom.xml` or `hitorro-util/pom.xml`

```xml
<!-- Hadoop AWS module for S3A support -->
<dependency>
    <groupId>org.apache.hadoop</groupId>
    <artifactId>hadoop-aws</artifactId>
    <version>3.4.1</version>
</dependency>

<!-- AWS SDK v2 Bundle (required by hadoop-aws 3.4.x) -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>bundle</artifactId>
    <version>2.29.29</version>
</dependency>

<!-- Exclude old dependencies if they cause conflicts -->
<dependency>
    <groupId>org.apache.hadoop</groupId>
    <artifactId>hadoop-aws</artifactId>
    <version>3.4.1</version>
    <exclusions>
        <exclusion>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-java-sdk-bundle</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

### Update Hadoop Core (if needed)

```xml
<!-- Update from old hadoop-core to hadoop-client -->
<dependency>
    <groupId>org.apache.hadoop</groupId>
    <artifactId>hadoop-client</artifactId>
    <version>3.4.1</version>
</dependency>
```

## Step 2: Update HTS3FileSystem Implementation

**File**: `hitorro-util/src/main/java/com/hitorro/util/basefile/fs/s3/HTS3FileSystem.java`

### Complete Updated Implementation

```java
/*
 * Copyright (c) 2006-2025 Chris Collins
 * ... (keep existing copyright)
 */
package com.hitorro.util.basefile.fs.s3;

import com.hitorro.util.basefile.fs.dfs.DFSFileSystem;
import com.hitorro.util.core.Env;
import com.hitorro.util.core.Log;
import com.hitorro.util.core.string.Fmt;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;

/**
 * S3 FileSystem implementation using Hadoop S3A with AWS SDK v2.
 * 
 * This implementation uses Hadoop's S3A FileSystem which provides:
 * - Modern AWS SDK v2 (actively supported)
 * - Better performance (2-5x faster than old S3N)
 * - IAM role support
 * - Server-side encryption (SSE-S3, SSE-KMS, SSE-C)
 * - Multipart uploads for large files
 * - Better error handling and retries
 * 
 * URI Format: s3a://bucket-name/path/to/file
 * 
 * Configuration:
 * - fs.s3a.access.key: AWS access key ID
 * - fs.s3a.secret.key: AWS secret access key
 * - fs.s3a.aws.credentials.provider: Credential provider class
 * 
 * @see <a href="https://hadoop.apache.org/docs/r3.4.1/hadoop-aws/tools/hadoop-aws/index.html">Hadoop-AWS Documentation</a>
 */
public class HTS3FileSystem extends DFSFileSystem {

    private String bucketName;
    private String secretAccessKey;
    private String accessKey;
    private String region;  // Optional: AWS region
    
    /**
     * Create S3 filesystem with explicit credentials.
     * 
     * @param bucketName S3 bucket name
     * @param secretAccessKey AWS secret access key
     * @param accessKey AWS access key ID
     */
    public HTS3FileSystem(String bucketName, String secretAccessKey, String accessKey) {
        this(bucketName, secretAccessKey, accessKey, null);
    }
    
    /**
     * Create S3 filesystem with explicit credentials and region.
     * 
     * @param bucketName S3 bucket name
     * @param secretAccessKey AWS secret access key
     * @param accessKey AWS access key ID
     * @param region AWS region (e.g., "us-east-1"), null for default
     */
    public HTS3FileSystem(String bucketName, String secretAccessKey, String accessKey, String region) {
        // Use s3a:// protocol (modern S3A implementation)
        super(Fmt.S("s3a://%s", bucketName), Fmt.S("s3a://%s", bucketName));
        this.bucketName = bucketName;
        this.secretAccessKey = secretAccessKey;
        this.accessKey = accessKey;
        this.region = region;
    }

    /**
     * Configure S3 filesystem from configuration object.
     * 
     * @param config S3 configuration
     */
    public HTS3FileSystem(S3Config config) {
        this(config.bucket, config.secretAccessKey, config.accessKey, config.region);
    }

    @Override
    protected FileSystem getFileSystem() {
        FileSystem ret = null;

        try {
            URI uri = new URI(hdfsURI);
            Configuration conf = new Configuration(false);

            // S3A FileSystem implementation
            conf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem");
            
            // Credentials configuration
            if (accessKey != null && secretAccessKey != null) {
                // Explicit credentials
                conf.set("fs.s3a.access.key", accessKey);
                conf.set("fs.s3a.secret.key", secretAccessKey);
                conf.set("fs.s3a.aws.credentials.provider", 
                        "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider");
            } else {
                // Use default credential provider chain (IAM roles, etc.)
                conf.set("fs.s3a.aws.credentials.provider",
                        "com.amazonaws.auth.DefaultAWSCredentialsProviderChain");
            }
            
            // Region configuration
            if (region != null && !region.isEmpty()) {
                conf.set("fs.s3a.endpoint.region", region);
            }
            
            // Performance tuning
            conf.set("fs.s3a.connection.maximum", "100");  // Max connections
            conf.set("fs.s3a.threads.max", "64");          // Thread pool size
            conf.set("fs.s3a.fast.upload", "true");        // Use fast upload
            conf.set("fs.s3a.block.size", "134217728");    // 128MB block size
            
            // Multipart upload configuration (for files > 100MB)
            conf.set("fs.s3a.multipart.size", "104857600");      // 100MB parts
            conf.set("fs.s3a.multipart.threshold", "209715200"); // 200MB threshold
            
            // Buffer configuration
            conf.set("fs.s3a.buffer.dir", Env.getTempDirectory().getAbsolutePath());
            
            // Retry configuration
            conf.set("fs.s3a.retry.limit", "7");
            conf.set("fs.s3a.retry.interval", "500ms");
            
            // Optional: Enable server-side encryption
            // conf.set("fs.s3a.server-side-encryption-algorithm", "AES256");
            // Or with KMS:
            // conf.set("fs.s3a.server-side-encryption-algorithm", "SSE-KMS");
            // conf.set("fs.s3a.server-side-encryption.key", "arn:aws:kms:...");
            
            ret = FileSystem.get(uri, conf);
            triedAndFailed = false;
            
            Log.util.info("✓ Connected to S3 bucket: %s (region: %s)", 
                         bucketName, region != null ? region : "default");
            return ret;
            
        } catch (IOException e) {
            Log.util.error("Unable to connect to S3 filesystem %s: %s", hdfsURI, e.getMessage(), e);
            triedAndFailed = true;
        } catch (URISyntaxException e) {
            Log.util.error("URI for S3 filesystem incorrectly formed %s: %s", hdfsURI, e.getMessage(), e);
            triedAndFailed = true;
        }

        return ret;
    }
    
    /**
     * Get the S3 bucket name.
     */
    public String getBucketName() {
        return bucketName;
    }
    
    /**
     * Get the configured AWS region.
     */
    public String getRegion() {
        return region;
    }
}
```

## Step 3: Update S3Config

**File**: `hitorro-util/src/main/java/com/hitorro/util/basefile/fs/s3/S3Config.java`

```java
package com.hitorro.util.basefile.fs.s3;

import com.hitorro.util.basefile.fs.configfactories.FileSystemConfig;

/**
 * Configuration for S3 filesystem.
 */
public class S3Config extends FileSystemConfig<HTS3FileSystem> {
    public String bucket;
    public String secretAccessKey;
    public String accessKey;
    public String region;  // NEW: AWS region
    
    public HTS3FileSystem getFileSystem() {
        return new HTS3FileSystem(this);
    }
}
```

## Step 4: Update S3PropertyFactory (if needed)

**File**: `hitorro-util/src/main/java/com/hitorro/util/basefile/fs/s3/S3PropertyFactory.java`

Ensure the protocol is registered correctly:

```java
@Override
public String getProtocol() {
    return "s3a";  // Changed from "s3" to "s3a"
}
```

**Note**: You may want to support BOTH `s3://` and `s3a://` during migration:

```java
@Override
public BaseFile getBaseFileFromPath(String path) throws IOException {
    // Support both old s3:// and new s3a:// URIs
    if (path.startsWith("s3://")) {
        Log.util.warn("Old s3:// URI detected, converting to s3a://: %s", path);
        path = path.replace("s3://", "s3a://");
    }
    
    return parseAndCreateS3File(path);
}
```

## Step 5: Configuration Migration

### Old Configuration (JetS3t)

```properties
# Old style (no longer supported)
fs.s3.awsAccessKeyId=AKIAIOSFODNN7EXAMPLE
fs.s3.awsSecretAccessKey=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
fs.s3.buffer.dir=/tmp/s3
```

### New Configuration (S3A with AWS SDK v2)

```properties
# Method 1: Explicit credentials (simple but less secure)
fs.s3a.access.key=AKIAIOSFODNN7EXAMPLE
fs.s3a.secret.key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
fs.s3a.endpoint.region=us-east-1

# Method 2: IAM Instance Profile (recommended for EC2)
fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.auth.IAMInstanceCredentialsProvider

# Method 3: Environment variables
# Just set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
fs.s3a.aws.credentials.provider=com.amazonaws.auth.EnvironmentVariableCredentialsProvider

# Method 4: Default credential chain (tries multiple sources)
fs.s3a.aws.credentials.provider=com.amazonaws.auth.DefaultAWSCredentialsProviderChain
```

### Backward Compatibility Helper

Add to `HTS3FileSystem`:

```java
private void loadLegacyConfig(Configuration conf) {
    // Support old fs.s3.* properties as fallback
    String oldAccessKey = conf.get("fs.s3.awsAccessKeyId");
    String oldSecretKey = conf.get("fs.s3.awsSecretAccessKey");
    
    if (oldAccessKey != null && this.accessKey == null) {
        Log.util.warn("Using legacy fs.s3.awsAccessKeyId config, please migrate to fs.s3a.access.key");
        this.accessKey = oldAccessKey;
    }
    
    if (oldSecretKey != null && this.secretAccessKey == null) {
        Log.util.warn("Using legacy fs.s3.awsSecretAccessKey config, please migrate to fs.s3a.secret.key");
        this.secretAccessKey = oldSecretKey;
    }
}
```

## Step 6: Testing Strategy

### Unit Tests

Create `HTS3FileSystemTest.java`:

```java
package com.hitorro.util.basefile.fs.s3;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import static org.junit.jupiter.api.Assertions.*;

public class HTS3FileSystemTest {
    
    @Test
    @EnabledIfEnvironmentVariable(named = "AWS_ACCESS_KEY_ID", matches = ".+")
    public void testS3Connection() throws Exception {
        String bucket = System.getenv("TEST_S3_BUCKET");
        String accessKey = System.getenv("AWS_ACCESS_KEY_ID");
        String secretKey = System.getenv("AWS_SECRET_ACCESS_KEY");
        
        HTS3FileSystem fs = new HTS3FileSystem(bucket, secretKey, accessKey);
        
        assertTrue(fs.isFileSystemAvailable(), "S3 filesystem should be available");
    }
    
    @Test
    @EnabledIfEnvironmentVariable(named = "AWS_ACCESS_KEY_ID", matches = ".+")
    public void testS3WriteAndRead() throws Exception {
        String bucket = System.getenv("TEST_S3_BUCKET");
        String accessKey = System.getenv("AWS_ACCESS_KEY_ID");
        String secretKey = System.getenv("AWS_SECRET_ACCESS_KEY");
        
        HTS3FileSystem fs = new HTS3FileSystem(bucket, secretKey, accessKey);
        BaseFile file = fs.getFile("test/test-file.txt");
        
        // Write
        String testData = "Hello S3A!";
        try (OutputStream os = file.getOutputStream()) {
            os.write(testData.getBytes());
        }
        
        assertTrue(file.exists(), "File should exist after write");
        
        // Read
        try (InputStream is = file.getInputStream()) {
            String readData = new String(is.readAllBytes());
            assertEquals(testData, readData, "Read data should match written data");
        }
        
        // Cleanup
        file.delete();
    }
}
```

### Integration Test Checklist

- [ ] Basic file operations (create, read, write, delete)
- [ ] Directory operations (mkdir, list, delete recursive)
- [ ] Large file uploads (>100MB, test multipart)
- [ ] Concurrent operations
- [ ] Error handling (network failures, permission errors)
- [ ] Performance benchmarks (compare with old implementation)
- [ ] IAM role authentication (if using EC2)
- [ ] Different regions
- [ ] Server-side encryption
- [ ] Path resolution (s3a:// URIs)

## Step 7: Deployment Checklist

### Pre-Deployment

- [ ] Review all code changes
- [ ] Run full test suite
- [ ] Performance benchmarks completed
- [ ] Documentation updated
- [ ] Configuration migration guide written
- [ ] Rollback plan documented

### Deployment

- [ ] Deploy to development environment
- [ ] Verify S3 connectivity
- [ ] Run smoke tests
- [ ] Deploy to staging
- [ ] Run integration tests
- [ ] Deploy to production (gradual rollout)
- [ ] Monitor logs for errors

### Post-Deployment

- [ ] Verify production S3 operations
- [ ] Monitor performance metrics
- [ ] Check for errors in logs
- [ ] Collect user feedback
- [ ] Update documentation with lessons learned

## Troubleshooting Guide

### Issue: ClassNotFoundException for S3AFileSystem

**Solution**: Ensure `hadoop-aws` is in classpath:
```bash
mvn dependency:tree | grep hadoop-aws
```

### Issue: NoSuchMethodError from AWS SDK

**Solution**: Conflict between AWS SDK v1 and v2. Exclude v1:
```xml
<exclusion>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-java-sdk</artifactId>
</exclusion>
```

### Issue: Access Denied errors

**Solution**: Verify IAM permissions for S3 bucket:
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::bucket-name/*",
    "arn:aws:s3:::bucket-name"
  ]
}
```

### Issue: Slow performance

**Solution**: Tune S3A parameters:
```properties
fs.s3a.connection.maximum=200
fs.s3a.threads.max=128
fs.s3a.fast.upload=true
fs.s3a.fast.upload.buffer=disk
```

### Issue: Connection timeouts

**Solution**: Increase timeout values:
```properties
fs.s3a.connection.timeout=200000
fs.s3a.connection.establish.timeout=5000
fs.s3a.attempts.maximum=10
```

## Rollback Plan

If issues occur:

1. **Immediate**: Revert to previous version
   ```bash
   git revert <commit-hash>
   mvn clean install
   ```

2. **Configuration**: Switch back to old properties
   ```properties
   # Re-enable old s3:// URIs
   hitorro.filesystem.s3.use-legacy=true
   ```

3. **Dependencies**: Restore JetS3t
   ```xml
   <dependency>
       <groupId>net.java.dev.jets3t</groupId>
       <artifactId>jets3t</artifactId>
       <version>0.9.4</version>
   </dependency>
   ```

## Performance Benchmarks

### Test Setup
- File sizes: 1MB, 10MB, 100MB, 1GB
- Operations: Write, Read, List, Delete
- Concurrent operations: 1, 10, 50 threads

### Expected Results (S3A vs JetS3t)

| Operation | JetS3t | S3A | Improvement |
|-----------|--------|-----|-------------|
| Write 1MB | 250ms | 150ms | 1.7x |
| Write 100MB | 5s | 2s | 2.5x |
| Read 1MB | 200ms | 100ms | 2x |
| List 1000 files | 2s | 800ms | 2.5x |

## Success Criteria

- [ ] All tests pass
- [ ] No regressions in functionality
- [ ] Performance equal or better than old implementation
- [ ] Documentation complete
- [ ] Production deployment successful
- [ ] No critical bugs in first week
- [ ] JetS3t dependency removed

## Next Steps

After successful S3A upgrade:

1. Consider removing old Hadoop 0.20.2 dependencies
2. Explore advanced S3A features:
   - S3 Select for in-place querying
   - S3 Object Lambda
   - Transfer acceleration
3. Implement S3 lifecycle policies for cost optimization
4. Set up CloudWatch metrics for monitoring
5. Document best practices for S3 usage in Hitorro

## References

- [Hadoop S3A Documentation](https://hadoop.apache.org/docs/r3.4.1/hadoop-aws/tools/hadoop-aws/index.html)
- [AWS SDK for Java v2](https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/home.html)
- [S3A Upgrade Guide](https://hadoop.apache.org/docs/r3.4.0/hadoop-aws/tools/hadoop-aws/aws_sdk_upgrade.html)
- [S3A Performance Tuning](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/performance.html)
