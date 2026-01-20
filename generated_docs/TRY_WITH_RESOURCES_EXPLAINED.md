# Try-With-Resources Explained

## The Pattern

```java
try (OutputStream os = largeFile.getOutputStream()) {
    // ... write data ...
}  // <- Automatically calls os.close() here!
```

## What Happens Automatically

When the `try` block exits (normally or via exception), Java **automatically** calls:

1. `os.flush()` - Flushes buffered data to the stream
2. `os.close()` - Closes the stream

This is guaranteed by the Java language specification for any class implementing `AutoCloseable`.

## Traditional vs Try-With-Resources

### Old Way (Before Java 7)

```java
OutputStream os = null;
try {
    os = largeFile.getOutputStream();
    os.write(data);
    os.flush();  // Must remember to flush
} finally {
    if (os != null) {
        try {
            os.close();  // Must remember to close
        } catch (IOException e) {
            // Handle exception
        }
    }
}
```

### Modern Way (Java 7+)

```java
try (OutputStream os = largeFile.getOutputStream()) {
    os.write(data);
    // flush() and close() happen automatically!
}
```

## Why We Added Explicit flush()

The code now has:

```java
try (OutputStream os = largeFile.getOutputStream()) {
    // ... write data ...
    
    os.flush();  // Explicit flush (documentation/clarity)
} // close() still called automatically
```

**Why add explicit flush if it's automatic?**

1. **Documentation** - Makes it clear we want data flushed before close
2. **Timing control** - Ensures flush happens before we exit the block
3. **Clarity** - Readers don't need to know about try-with-resources to understand the code

## Best Practice

**For production code**, both approaches are fine:

```java
// Implicit (relies on try-with-resources)
try (OutputStream os = getOutputStream()) {
    os.write(data);
}

// Explicit (self-documenting)
try (OutputStream os = getOutputStream()) {
    os.write(data);
    os.flush();
}
```

**For tests/examples**, explicit is often better because it's more educational.

## What Gets Called When

```java
try (OutputStream os = largeFile.getOutputStream()) {
    os.write(data);           // 1. Write to buffer
    os.flush();               // 2. Explicit: buffer → stream
} // 3. Automatic: flush() then close()
```

So actually `flush()` might be called **twice**:
1. Explicit call at line with `os.flush()`
2. Implicit call when try-with-resources calls `close()`

This is **safe and harmless** - calling flush() multiple times is idempotent (second call does nothing).

## Exception Handling

Try-with-resources also handles exceptions better:

```java
try (OutputStream os = getOutputStream()) {
    os.write(data);  // Exception here?
} // close() still called even if exception thrown!
```

If both the try block AND close() throw exceptions, try-with-resources will:
1. Propagate the original exception (from write)
2. Attach the close() exception as a "suppressed exception"

## Summary

✅ **Try-with-resources automatically flushes and closes**  
✅ **Adding explicit flush() is fine (documentation)**  
✅ **Both approaches work correctly**  
✅ **Explicit flush() makes code more self-documenting**  

The test now has explicit `flush()` for clarity, but the try-with-resources would have flushed and closed anyway! 🎯
