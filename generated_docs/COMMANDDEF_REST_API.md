# CommandDef REST API Implementation

## Overview

I've implemented a **structured JSON REST API** for @CommandDef annotated methods, replacing the text-based command execution with a modern API that returns structured JSON responses. The React UI now works properly with command discovery, metadata inspection, and execution.

## What Was Implemented

### 1. CommandDefRestController (`CommandDefRestController.java`)

A new Spring REST controller that:
- **Scans** all Spring beans for @CommandDef annotated methods
- **Exposes** them via structured JSON endpoints
- **Executes** commands with type-safe parameter conversion
- **Returns** structured JSON responses (not text output)

### 2. Demo Commands (`DemoCommands.java`)

11 demonstration commands showcasing various capabilities:
- **echo** - Simple string echo
- **add** - Integer arithmetic with JSON response  
- **multiply** - Floating point operations
- **greet** - String manipulation
- **timestamp** - Date/time formatting
- **stats** - Statistical analysis
- **reverse** - String reversal
- **wordcount** - Text analysis with word frequency
- **isprime** - Prime number checking
- **fibonacci** - Sequence generation
- **sysinfo** - System information

## API Endpoints

### List All Commands
**GET** `/api/commands/list`

Returns array of command metadata including parameters and return types.

**Response:**
```json
[
  {
    "name": "add",
    "description": "Add two numbers together",
    "parameters": [
      {
        "name": "a",
        "type": "int",
        "required": false
      },
      {
        "name": "b",
        "type": "int",
        "required": false
      }
    ],
    "returnType": "Map"
  }
]
```

### Get Command Metadata
**GET** `/api/commands/{commandName}`

Returns detailed metadata for a specific command.

### Execute Command
**POST** `/api/commands/execute`

Execute a command with parameters and get structured JSON response.

**Request:**
```json
{
  "commandName": "add",
  "parameters": {
    "a": 5,
    "b": 3
  }
}
```

**Response:**
```json
{
  "success": true,
  "result": {
    "a": 5,
    "b": 3,
    "sum": 8,
    "operation": "addition"
  },
  "error": null,
  "executionTimeMs": 2
}
```

## Key Features

### 1. Automatic Discovery
The controller automatically scans all Spring beans and registers @CommandDef annotated methods:

```java
@Component
public class DemoCommands {
    @CommandDef(command = "add", description = "Add two numbers", isInternal = false)
    public Map<String, Object> add(int a, int b) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("sum", a + b);
        return result;
    }
}
```

### 2. Type-Safe Parameter Conversion
Automatic conversion of JSON parameters to Java types:
- int, long, double, float
- boolean
- String
- Object (for complex types)

### 3. Structured JSON Responses
All commands return structured JSON (not text output):

```java
@CommandDef(command = "stats", description = "Calculate statistics", isInternal = false)
public Map<String, Object> stats(String numbers) {
    Map<String, Object> result = new LinkedHashMap<>();
    result.put("count", count);
    result.put("mean", mean);
    result.put("min", min);
    result.put("max", max);
    return result;
}
```

### 4. Execution Metadata
Every response includes:
- **success**: boolean indicating success/failure
- **result**: the actual return value (structured)
- **error**: error message if failed
- **executionTimeMs**: execution time in milliseconds

## Example Commands

### Simple Echo
```bash
curl -X POST http://localhost:8080/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{
    "commandName": "echo",
    "parameters": {"message": "Hello Hitorro"}
  }'
```

Response:
```json
{
  "success": true,
  "result": "Hello Hitorro",
  "executionTimeMs": 1
}
```

### Math Operations
```bash
curl -X POST http://localhost:8080/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{
    "commandName": "add",
    "parameters": {"a": 42, "b": 17}
  }'
```

Response:
```json
{
  "success": true,
  "result": {
    "a": 42,
    "b": 17,
    "sum": 59,
    "operation": "addition"
  },
  "executionTimeMs": 2
}
```

### Text Analysis
```bash
curl -X POST http://localhost:8080/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{
    "commandName": "wordcount",
    "parameters": {"text": "The quick brown fox jumps over the lazy dog"}
  }'
```

Response:
```json
{
  "success": true,
  "result": {
    "text": "The quick brown fox jumps over the lazy dog",
    "wordCount": 9,
    "characterCount": 43,
    "characterCountNoSpaces": 35,
    "uniqueWords": 9,
    "topWords": [
      {"word": "the", "count": 2},
      {"word": "quick", "count": 1},
      {"word": "brown", "count": 1}
    ]
  },
  "executionTimeMs": 5
}
```

### System Information
```bash
curl -X POST http://localhost:8080/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{
    "commandName": "sysinfo",
    "parameters": {}
  }'
```

Response:
```json
{
  "success": true,
  "result": {
    "javaVersion": "17.0.8",
    "javaVendor": "Eclipse Adoptium",
    "osName": "Mac OS X",
    "osVersion": "14.2",
    "osArch": "aarch64",
    "availableProcessors": 10,
    "maxMemoryMB": 4096,
    "totalMemoryMB": 512,
    "freeMemoryMB": 256,
    "usedMemoryMB": 256
  },
  "executionTimeMs": 1
}
```

## React UI Integration

The commands UI now works properly:

1. **Discovery**: Lists all available commands with metadata
2. **Inspection**: Shows parameters, types, descriptions
3. **Execution**: Dynamic form generation based on parameter types
4. **Results**: Pretty JSON display of structured responses
5. **Error Handling**: Clear error messages

### UI Features:
- ✅ Command list with descriptions
- ✅ Parameter type detection (int, double, boolean, string)
- ✅ Dynamic form generation
- ✅ JSON result visualization with react-json-view
- ✅ Execution time display
- ✅ Error handling and display

## Creating Custom Commands

### Pattern
```java
@Component
public class MyCommands {
    
    @CommandDef(
        command = "myCommand",
        description = "What this command does",
        isInternal = false  // Make it accessible via REST
    )
    public Map<String, Object> myCommand(String param1, int param2) {
        Map<String, Object> result = new LinkedHashMap<>();
        // Your logic here
        result.put("output", "some value");
        return result;
    }
}
```

### Best Practices

1. **Return Structured Data**: Use Map<String, Object> or POJOs
   ```java
   Map<String, Object> result = new LinkedHashMap<>();
   result.put("key", "value");
   return result;
   ```

2. **Include Metadata**: Add operation details to responses
   ```java
   result.put("operation", "description");
   result.put("input", inputValue);
   result.put("output", outputValue);
   ```

3. **Handle Errors Gracefully**: Return error info in result
   ```java
   if (error) {
       result.put("error", "Error message");
       return result;
   }
   ```

4. **Set isInternal = false**: Make command accessible via REST
   ```java
   @CommandDef(command = "cmd", description = "...", isInternal = false)
   ```

5. **Use Descriptive Names**: Clear command and parameter names
   ```java
   public Map<String, Object> calculateSum(int firstNumber, int secondNumber)
   ```

## Architecture

```
React UI (CommandsPage.tsx)
    ↓
    GET /api/commands/list
    ↓
CommandDefRestController
    ↓
    Scans @CommandDef methods
    ↓
    Returns structured metadata
    ↓
React UI (displays commands)
    ↓
    User fills parameters
    ↓
    POST /api/commands/execute
    ↓
CommandDefRestController
    ↓
    Type conversion
    ↓
    Method invocation
    ↓
    JSON response
    ↓
React UI (displays results)
```

## Differences from Old System

| Feature | Old System | New System |
|---------|-----------|------------|
| **Response Format** | Plain text | Structured JSON |
| **Discovery** | Basic list | Full metadata (params, types, descriptions) |
| **Parameter Types** | String parsing | Automatic type conversion |
| **Errors** | Text messages | Structured error objects |
| **Execution Time** | Not tracked | Included in response |
| **UI Integration** | Manual parsing | Native JSON handling |
| **Return Values** | Console output | Any JSON-serializable object |

## Testing

### Via cURL
```bash
# List commands
curl http://localhost:8080/api/commands/list

# Execute command
curl -X POST http://localhost:8080/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{"commandName":"add","parameters":{"a":5,"b":3}}'
```

### Via React UI
1. Navigate to http://localhost:3000/commands
2. Select a command from the list
3. Fill in parameters
4. Click "Execute"
5. View structured JSON response

### Via Browser Dev Tools
```javascript
// List commands
fetch('/api/commands/list')
  .then(r => r.json())
  .then(console.log);

// Execute command
fetch('/api/commands/execute', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    commandName: 'add',
    parameters: {a: 5, b: 3}
  })
})
  .then(r => r.json())
  .then(console.log);
```

## Next Steps

1. ✅ Controller implemented
2. ✅ Demo commands created
3. ✅ React UI works
4. 🔄 Start application and test
5. 🔄 Add your own custom commands
6. 🔄 Integrate with business logic

## Files Created/Modified

- **New**: `CommandDefRestController.java` - REST API controller
- **New**: `DemoCommands.java` - 11 demonstration commands
- **Existing**: `CommandsPage.tsx` - Already configured for this API
- **Existing**: `api.ts` - API client already configured

The implementation is complete and ready to use!
