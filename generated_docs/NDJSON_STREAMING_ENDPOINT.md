# NDJson Streaming Enrichment Endpoint

## Overview

A new streaming endpoint has been added to the JVS Controller to support **NDJson (Newline-Delimited JSON)** format for bulk enrichment operations. This allows you to send a stream of JSON objects and receive enriched results back, which is much more efficient for processing large datasets.

## Endpoint Details

- **URL**: `/api/jvs/enrich/stream`
- **Method**: `POST`
- **Content-Type**: `application/octet-stream`
- **Response Type**: `application/x-ndjson`
- **Query Parameters**:
  - `tags` (optional): Comma-separated enrichment tags (e.g., `ner,answers,segmented,parsed`)

## How It Works

The endpoint leverages the existing Hitorro iterator/sink architecture in a simple, elegant pattern:

```java
new JSONIterator(inputStream)
    .map(new JsonNodeEnrichmentMapper(tags))
    .sink(new JsonSink(outputStream))
```

Where:
1. **`JSONIterator`**: Parses InputStream as a stream of JsonNode objects
2. **`map()`**: Applies enrichment to each JsonNode (JsonNode → JVS → enriched JVS → JsonNode)
3. **`JsonSink`**: Outputs enriched JsonNode objects as NDJson format

```
InputStream → JSONIterator → map(enrichment) → JsonSink → NDJson Output
```

## Usage Examples

### Example 1: Basic Enrichment (curl)

```bash
curl -X POST "http://localhost:8080/api/jvs/enrich/stream" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @input.ndjson \
  -o output.ndjson
```

### Example 2: With Tags (curl)

```bash
curl -X POST "http://localhost:8080/api/jvs/enrich/stream?tags=ner,answers,segmented" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @input.ndjson \
  -o output.ndjson
```

### Example 3: Java Client

```java
import java.io.*;
import java.net.*;

// Create connection
URL url = new URL("http://localhost:8080/api/jvs/enrich/stream?tags=ner");
HttpURLConnection conn = (HttpURLConnection) url.openConnection();
conn.setRequestMethod("POST");
conn.setRequestProperty("Content-Type", "application/octet-stream");
conn.setDoOutput(true);

// Send NDJson data
try (OutputStream os = conn.getOutputStream();
     FileInputStream fis = new FileInputStream("input.ndjson")) {
    byte[] buffer = new byte[8192];
    int bytesRead;
    while ((bytesRead = fis.read(buffer)) != -1) {
        os.write(buffer, 0, bytesRead);
    }
}

// Read enriched results
try (InputStream is = conn.getInputStream();
     BufferedReader reader = new BufferedReader(new InputStreamReader(is))) {
    String line;
    while ((line = reader.readLine()) != null) {
        // Process each enriched JSON object
        System.out.println(line);
    }
}
```

### Example 4: Python Client

```python
import requests

with open('input.ndjson', 'rb') as f:
    response = requests.post(
        'http://localhost:8080/api/jvs/enrich/stream',
        params={'tags': 'ner,answers'},
        headers={'Content-Type': 'application/octet-stream'},
        data=f,
        stream=True
    )
    
    # Process streaming response line by line
    for line in response.iter_lines():
        if line:
            enriched_obj = json.loads(line)
            print(enriched_obj)
```

## Input Format

The input should be **NDJson (Newline-Delimited JSON)**, where each line is a valid JSON object:

```json
{"ht_type": "core_mlselem", "text": "Beautiful house in San Francisco"}
{"ht_type": "core_mlselem", "text": "Modern apartment in New York"}
{"ht_type": "core_mlselem", "text": "Cozy cottage near the beach"}
```

## Output Format

The output is also **NDJson**, with each enriched object on a separate line:

```json
{"ht_type":"core_mlselem","text":"Beautiful house in San Francisco","ner_locations":["San Francisco"],...}
{"ht_type":"core_mlselem","text":"Modern apartment in New York","ner_locations":["New York"],...}
{"ht_type":"core_mlselem","text":"Cozy cottage near the beach",...}
```

## Advantages Over Single Object Endpoint

1. **Efficiency**: Stream processing avoids loading entire dataset into memory
2. **Scalability**: Can handle millions of records without memory issues
3. **Throughput**: Pipeline architecture (read → enrich → write) maximizes performance
4. **Real-time**: Results stream back as they're processed, no waiting for entire batch
5. **Simple Integration**: Standard NDJson format is widely supported

## Error Handling

- If the stream processing fails, returns HTTP 500 with an error message
- Individual object enrichment errors are logged but don't stop the stream
- Failed objects return the original JSON in the output stream

## Performance Notes

- The endpoint uses the iterator/sink pattern which is highly optimized
- Memory usage remains constant regardless of input size
- Processing is single-threaded per request (use multiple requests for parallelism)
- For CPU-intensive enrichment, consider using the `mapParallel()` variant in future enhancements

## Comparison with Original Endpoint

| Feature | `/enrich` (original) | `/enrich/stream` (new) |
|---------|---------------------|------------------------|
| Input Format | Single JSON object | NDJson stream |
| Output Format | Wrapped response with metadata | NDJson stream |
| Memory Usage | Loads entire object | Constant (streaming) |
| Batch Support | One at a time | Unlimited |
| Response Time | Immediate | Streaming |
| Best For | Interactive UI, single docs | Bulk processing, ETL |

## Implementation Details

The implementation uses the Hitorro iterator framework with a clean, functional approach:

```java
// Core streaming pattern
new JSONIterator(reader)
    .map(new JsonNodeEnrichmentMapper(tags))
    .sink(new JsonSink(outputStream));
```

The `JsonNodeEnrichmentMapper` wraps `JVS2JVSEnrichMapper` to bridge JsonNode and JVS:

```java
private static class JsonNodeEnrichmentMapper implements Function<JsonNode, JsonNode> {
    private final JVS2JVSEnrichMapper enrichMapper;
    
    public JsonNodeEnrichmentMapper(String... tags) {
        this.enrichMapper = new JVS2JVSEnrichMapper(tags);
    }
    
    @Override
    public JsonNode apply(JsonNode jsonNode) {
        JVS jvs = new JVS(jsonNode);
        JVS enriched = enrichMapper.apply(jvs);
        return enriched != null ? enriched.getJsonNode() : jsonNode;
    }
}
```

This elegant pattern leverages the existing iterator/sink framework for clean, maintainable code that follows your architectural vision.
