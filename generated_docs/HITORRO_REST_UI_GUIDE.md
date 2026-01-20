# Hitorro REST API Explorer - UI Guide

## Overview

The **REST API Explorer** is an interactive web interface for discovering, testing, and interacting with Hitorro REST endpoints. It provides a user-friendly way to explore the API, test endpoints, view streaming responses, and download data.

## Accessing the UI

1. **Start the application:**
   ```bash
   cd hitorro-example-springboot
   mvn spring-boot:run
   ```

2. **Open your browser:**
   ```
   http://localhost:3000
   ```

3. **Click the "REST API Explorer" tab**

## Features

### 🔍 Endpoint Discovery

**What it does:** Automatically discovers all REST-enabled commands from the Hitorro CommandRegistry

**Features:**
- Lists all 20+ REST endpoints
- Shows HTTP methods supported (GET, POST, PUT, DELETE)
- Displays parameter information
- Shows internal/public status
- Real-time filtering

**How to use:**
1. Check "Show internal endpoints" to see all endpoints (including debugging commands)
2. Browse the list of available endpoints
3. Click an endpoint to select it for testing

### 🧪 Interactive Testing

**What it does:** Test REST endpoints with a visual interface

**Features:**
- HTTP method selection
- Parameter input forms
- Execute button
- Real-time results
- Error handling

**How to use:**
1. Select an endpoint from the list
2. Choose HTTP method (GET, POST, PUT, DELETE)
3. Fill in parameters
4. Click "Execute GET/POST/etc"
5. View results in formatted JSON

### 📡 Streaming Support

**What it does:** Generate direct URLs for streaming endpoints and file downloads

**Features:**
- One-click URL generation
- Open in new tab
- Download directly
- Copy URL to clipboard

**How to use:**
1. Select a streaming endpoint (e.g., CSV export)
2. Fill in parameters
3. Click "📡 Get Stream URL"
4. Choose action:
   - **Open in New Tab** - View streaming response
   - **Download** - Save to file
   - **Copy URL** - Use in curl/wget

### 📊 Response Viewer

**What it does:** Display execution results with detailed information

**Features:**
- Success/error indication
- HTTP status codes
- Response headers (expandable)
- Formatted JSON body
- Syntax highlighting
- Scrollable for large responses

## UI Walkthrough

### Left Panel: Endpoint List

```
┌─────────────────────────────────────┐
│ Endpoints                           │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ demo.echo        [GET]          │ │
│ │ Echo back the input message     │ │
│ │ /demo.echo                      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ demo.add         [GET][POST]    │ │
│ │ Add two numbers together        │ │
│ │ /demo.add                       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ env.hostip       [GET]          │ │
│ │ Host IP address                 │ │
│ │ /env.hostip                     │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Color coding:**
- **Green badge (GET)** - Read operations
- **Blue badge (POST)** - Create operations
- **Orange badge (PUT)** - Update operations
- **Red badge (DELETE)** - Delete operations
- **Yellow badge (INTERNAL)** - Internal/debugging commands

### Right Panel: Testing Interface

```
┌────────────────────────────────────┐
│ Test Endpoint                      │
├────────────────────────────────────┤
│ demo.echo                          │
│ Echo back the input message        │
│                                    │
│ HTTP Method:  [GET] POST PUT       │
│                                    │
│ Parameters:                        │
│ ┌────────────────────────────────┐ │
│ │ message * (string)             │ │
│ │ [                             ]│ │
│ │ Message to echo                │ │
│ └────────────────────────────────┘ │
│                                    │
│ [Execute GET] [📡 Get Stream URL] │
└────────────────────────────────────┘
```

### Response Display

```
┌────────────────────────────────────┐
│ ✅ Success              HTTP 200   │
├────────────────────────────────────┤
│ ▼ Response Headers                 │
│                                    │
│ Response Body                      │
│ ┌────────────────────────────────┐ │
│ │ {                              │ │
│ │   "success": true,             │ │
│ │   "command": "demo.echo",      │ │
│ │   "result": {                  │ │
│ │     "value": "Hello World"     │ │
│ │   },                           │ │
│ │   "executionTimeMs": 3         │ │
│ │ }                              │ │
│ └────────────────────────────────┘ │
│ [Clear Result]                     │
└────────────────────────────────────┘
```

## Example Workflows

### Example 1: Test a Simple Command

**Goal:** Echo a message

**Steps:**
1. Select `demo.echo` from endpoint list
2. HTTP method automatically set to GET
3. Enter "Hello World" in the `message` parameter
4. Click "Execute GET"
5. View result: `{"value": "Hello World"}`

**Expected result:**
```json
{
  "success": true,
  "command": "demo.echo",
  "operation": "Get",
  "result": {
    "value": "Hello World"
  },
  "executionTimeMs": 3
}
```

### Example 2: Test Multi-Parameter Command

**Goal:** Add two numbers

**Steps:**
1. Select `demo.add` from endpoint list
2. Choose GET or POST method
3. Enter `a = 10`
4. Enter `b = 20`
5. Click "Execute"
6. View result showing sum = 30

**Expected result:**
```json
{
  "success": true,
  "command": "demo.add",
  "result": [
    {"key": "a", "value": "10"},
    {"key": "b", "value": "20"},
    {"key": "sum", "value": "30"}
  ]
}
```

### Example 3: Stream/Download Data

**Goal:** Get a streaming URL for large dataset export

**Steps:**
1. Select a streaming endpoint (e.g., CSV export command)
2. Fill in any required parameters
3. Click "📡 Get Stream URL"
4. URL displayed with options:
   - Click "Open in New Tab" to view stream
   - Click "Download" to save file
   - Click "Copy URL" to use with curl

**Stream URL example:**
```
http://localhost:8080/api/rest/export.csv?format=full&limit=1000
```

**Usage with curl:**
```bash
curl "http://localhost:8080/api/rest/export.csv?format=full&limit=1000" > data.csv
```

### Example 4: Test POST with JSON

**Goal:** Send JSON data via POST

**Steps:**
1. Select endpoint that supports POST
2. Choose "POST" method
3. Enter parameters (will be sent as JSON body)
4. Click "Execute POST"
5. View response

**What happens:**
```javascript
// Request sent:
POST /api/rest/demo.add
Content-Type: application/json

{
  "a": 100,
  "b": 200
}

// Response received:
{
  "success": true,
  "result": [{"key": "sum", "value": "300"}]
}
```

### Example 5: View System Information

**Goal:** Get system properties without parameters

**Steps:**
1. Select `demo.sysinfo`
2. No parameters needed
3. Click "Execute GET"
4. View 9+ system properties

**Expected result:**
```json
{
  "success": true,
  "command": "demo.sysinfo",
  "result": [
    {"key": "javaVersion", "value": "21.0.7"},
    {"key": "osName", "value": "Mac OS X"},
    {"key": "osVersion", "value": "26.2"},
    {"key": "userDir", "value": "/Users/..."},
    ...
  ]
}
```

## Advanced Features

### Testing Internal Commands

**Enable:** Check "Show internal endpoints" checkbox

**What it shows:**
- System diagnostic commands
- Debug commands
- Administrative operations
- Internal utilities

**Examples:**
- `bags.loadtoqueue` - Queue operations
- `cluster.list` - Cluster information
- `counters.print` - Performance counters
- `commands` - Command registry dump

### Multiple HTTP Methods

Some endpoints support multiple HTTP methods (GET, POST, PUT, DELETE).

**Example:** Resource management command
```
Command: resource.manage
Methods: [GET] [POST] [PUT] [DELETE]

GET    - Read resource
POST   - Create resource
PUT    - Update resource
DELETE - Remove resource
```

**Testing:**
1. Select the command
2. Click method button (GET, POST, etc.)
3. Method button highlights when selected
4. Execute button updates: "Execute GET", "Execute POST", etc.

### Response Headers

Click "Response Headers" to expand and view:
- `Content-Type`
- `Content-Length`
- `X-Custom-Headers`
- Timing information
- Cache headers

### Error Handling

**404 Not Found:**
```json
{
  "error": "Command not found: nonexistent",
  "success": false
}
```

**405 Method Not Allowed:**
```json
{
  "error": "Method not allowed. Command supports: GET",
  "success": false,
  "allowedMethods": ["GET"]
}
```

**500 Internal Error:**
```json
{
  "success": false,
  "error": "Parameter validation failed: 'amount' is required"
}
```

## Tips & Tricks

### 1. Quick Testing

Use keyboard shortcuts:
- Tab through parameter fields
- Enter to submit (when focused on last parameter)

### 2. Copy-Paste JSON

For POST/PUT requests:
1. Get stream URL
2. Copy URL
3. Use with curl to send custom JSON:
   ```bash
   curl -X POST "http://localhost:8080/api/rest/command" \
     -H "Content-Type: application/json" \
     -d '{"custom": "data"}'
   ```

### 3. Save Responses

Click in response area and Cmd+A (Mac) or Ctrl+A (Windows) to select all, then copy.

### 4. Test Streaming

For CSV/large data:
1. Use "Get Stream URL"
2. Open in new tab to see progressive loading
3. Or download directly to file

### 5. Compare Methods

Test same endpoint with different HTTP methods:
1. Execute with GET
2. Copy result
3. Switch to POST
4. Execute again
5. Compare responses

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Navigate tabs | Tab |
| Submit form | Enter (on last input) |
| Select all text | Cmd/Ctrl + A |
| Copy text | Cmd/Ctrl + C |
| Close modal | Escape |

## Troubleshooting

### Endpoint not appearing

**Problem:** Expected endpoint not in list

**Solutions:**
1. Check "Show internal endpoints" if it's internal
2. Verify command has `restOperations` in `@CommandDef`
3. Restart application to reload commands

### Execution fails with 404

**Problem:** Command returns 404

**Solutions:**
1. Verify command name is correct
2. Check if command is registered (look in application logs)
3. Try refreshing the discovery list

### Parameters not working

**Problem:** Parameters not passed correctly

**Solutions:**
1. Check parameter names match exactly
2. For POST, ensure Content-Type is application/json
3. Check application logs for validation errors

### Streaming URL not working

**Problem:** Stream URL doesn't download

**Solutions:**
1. Open URL in new tab first to check response
2. Verify command supports streaming (has `getHttpResponse()`)
3. Check for CORS issues (F12 → Console)

## Browser Compatibility

**Tested browsers:**
- ✅ Chrome 120+
- ✅ Firefox 120+
- ✅ Safari 17+
- ✅ Edge 120+

**Required features:**
- JavaScript enabled
- Cookies enabled
- LocalStorage enabled

## Performance

**Discovery:** < 100ms for 20+ endpoints  
**Execution:** 1-10ms typical command  
**Streaming:** Progressive loading, no timeout  
**UI Updates:** Real-time, < 16ms

## Summary

The REST API Explorer provides:
- ✅ **Discovery** - Find all REST endpoints
- ✅ **Testing** - Execute commands interactively
- ✅ **Streaming** - Handle large datasets
- ✅ **Downloading** - Save results to files
- ✅ **Debugging** - View headers and errors
- ✅ **Documentation** - Self-documenting API

**Access it now at:** `http://localhost:3000` → "REST API Explorer" tab
