#!/bin/bash

# Test script for NDJson streaming enrichment endpoint

echo "=== Testing NDJson Streaming Enrichment Endpoint ==="
echo ""

# Configuration
HOST="localhost:8080"
ENDPOINT="/api/jvs/enrich/stream"
INPUT_FILE="test-ndjson-input.ndjson"
OUTPUT_FILE="test-ndjson-output.ndjson"

# Test 1: Basic enrichment (no tags)
echo "Test 1: Basic enrichment (default tags)"
curl -X POST "http://${HOST}${ENDPOINT}" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @${INPUT_FILE} \
  -o ${OUTPUT_FILE} \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

if [ $? -eq 0 ]; then
  echo "✓ Request successful"
  echo "Output written to: ${OUTPUT_FILE}"
  echo "Lines processed: $(wc -l < ${OUTPUT_FILE})"
  echo ""
else
  echo "✗ Request failed"
  echo ""
fi

# Test 2: Enrichment with specific tags
echo "Test 2: Enrichment with tags (ner,answers)"
curl -X POST "http://${HOST}${ENDPOINT}?tags=ner,answers" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @${INPUT_FILE} \
  -w "\nHTTP Status: %{http_code}\n" \
  -s

if [ $? -eq 0 ]; then
  echo "✓ Request successful with tags"
  echo ""
else
  echo "✗ Request failed"
  echo ""
fi

# Test 3: Show sample output (first enriched object)
echo "Test 3: Sample enriched output (first object)"
if [ -f ${OUTPUT_FILE} ]; then
  echo "---"
  head -n 1 ${OUTPUT_FILE} | python3 -m json.tool 2>/dev/null || head -n 1 ${OUTPUT_FILE}
  echo "---"
else
  echo "No output file found"
fi

echo ""
echo "=== Tests Complete ==="
