# New Document Transformers Guide

This guide covers the 5 new transformers added to Hitorro for modern document processing and AI/LLM integration.

## Table of Contents

1. [Quick Start](#quick-start)
2. [AI Service Setup](#ai-service-setup)
3. [Non-AI Transformers](#non-ai-transformers)
   - [DocumentEmbeddingPreprocessor](#documentembeddingpreprocessor)
   - [SpreadsheetToJSONTransformer](#spreadsheetto jsontransformer)
   - [PresentationToHTMLTransformer](#presentationtohtmltransformer)
3. [AI-Powered Transformers](#ai-powered-transformers)
   - [DocumentSummarizerTransformer](#documentsummarizertransformer)
   - [DocumentQATransformer](#documentqatransformer)
4. [Configuration](#configuration)
5. [Examples](#examples)

---

## Quick Start

### ✅ Ready to Use (No Setup Required)

These 3 transformers work immediately after building Hitorro:

1. **DocumentEmbeddingPreprocessor** - Clean text for vector embeddings
2. **SpreadsheetToJSONTransformer** - Convert Excel/CSV to JSON
3. **PresentationToHTMLTransformer** - Convert PowerPoint to HTML5

### ⚠️ Require AI Setup

These 2 transformers need Ollama installed and configured:

4. **DocumentSummarizerTransformer** - Requires AI service
5. **DocumentQATransformer** - Requires AI service

**All transformers are included in the `hitorro-basedms-3.0.0.jar` and `hitorro-spring-boot-autoconfigure-1.0.0.jar`**

---

## AI Service Setup

The AI-powered transformers use **Spring AI** with **Ollama** for local LLM inference.

### 1. Install Ollama

```bash
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama service
ollama serve
```

### 2. Pull Models

```bash
# Chat/completion model (for summarization, Q&A)
ollama pull llama3.2

# Embedding model (for vector search)
ollama pull nomic-embed-text
```

### 3. Configure Spring Boot Application

Add to `application.yml` (or use `application-ai.yml` profile):

```yaml
# Enable Hitorro AI service
hitorro:
  ai:
    enabled: true
    model-name: llama3.2

# Configure Spring AI with Ollama
spring:
  ai:
    ollama:
      base-url: http://localhost:11434
      chat:
        options:
          model: llama3.2
          temperature: 0.7
      embedding:
        options:
          model: nomic-embed-text
```

### 4. Run with AI Profile

```bash
# Start your application with AI enabled
java -jar your-app.jar --spring.profiles.active=ai

# Or via Maven
mvn spring-boot:run -Dspring-boot.run.profiles=ai
```

### Architecture

```
┌─────────────────┐
│  Transformer    │
│   (basedms)     │
└────────┬────────┘
         │
         │ AIServiceRegistry.getInstance()
         v
┌─────────────────┐
│   AIService     │
│  (interface)    │
└────────┬────────┘
         │
         v
┌─────────────────┐     ┌──────────────┐
│ OllamaAIService │────>│   Ollama     │
│  (Spring AI)    │     │  (localhost) │
└─────────────────┘     └──────────────┘
```

---

## Non-AI Transformers

### DocumentEmbeddingPreprocessor

**Purpose**: Clean and normalize text for vector embedding generation.

**Method Name**: `embedding_preprocessor`

**Use Cases**:
- Prepare text for vector databases (Pinecone, Weaviate, Chroma)
- Clean documents before feeding to LLMs
- Normalize text for semantic search

**Parameters**:
```json
{
  "lowercase": false,           // Convert to lowercase
  "removeUrls": true,           // Remove URLs → [URL]
  "removeEmails": true,         // Remove emails → [EMAIL]
  "removeSpecialChars": false,  // Keep only letters/numbers/punctuation
  "removeHeaders": true,        // Remove "Page 1", "Chapter 2", etc.
  "maxLineLength": 0            // Wrap long lines (0 = no limit)
}
```

**Example**:

Input (dirty.txt):
```
Visit https://example.com for more info!
Contact us at support@example.com

Page 1 of 10

This is the actual content with émojis 🎉 and special chars: @#$%
```

Output (clean.txt):
```
Visit [URL] for more info!
Contact us at [EMAIL]

This is the actual content with émojis  and special chars:
```

---

### SpreadsheetToJSONTransformer

**Purpose**: Convert Excel/CSV files to JSON for data pipelines and APIs.

**Method Name**: `spreadsheet_to_json`

**Use Cases**:
- Data import from Excel to databases
- API integration with spreadsheet data
- Convert reports to machine-readable format

**Parameters**:
```json
{
  "sheetIndex": 0,              // Which sheet (0 = first)
  "sheetName": "Sheet1",        // Or specify by name
  "hasHeaders": true,           // First row = column names
  "format": "array",            // "array", "ndjson", or "object"
  "includeMetadata": false,     // Include sheet metadata
  "emptyValue": null,           // Value for empty cells
  "dateFormat": "yyyy-MM-dd"    // Date formatting
}
```

**Output Formats**:

**Array** (default):
```json
[
  {"Name": "John Doe", "Age": 30, "Email": "john@example.com"},
  {"Name": "Jane Smith", "Age": 25, "Email": "jane@example.com"}
]
```

**NDJSON** (newline-delimited):
```
{"Name": "John Doe", "Age": 30, "Email": "john@example.com"}
{"Name": "Jane Smith", "Age": 25, "Email": "jane@example.com"}
```

**Object** (with metadata):
```json
{
  "data": [
    {"Name": "John Doe", "Age": 30},
    {"Name": "Jane Smith", "Age": 25}
  ],
  "metadata": {
    "sheetName": "Employees",
    "rowCount": 2,
    "columnCount": 3
  }
}
```

---

### PresentationToHTMLTransformer

**Purpose**: Convert PowerPoint presentations to interactive HTML5 for web display.

**Method Name**: `presentation_to_html`

**Use Cases**:
- Publish presentations on websites
- Create accessible presentation archives
- Training materials distribution

**Parameters**:
```json
{
  "includeNotes": false,        // Include speaker notes
  "createIndex": true,          // Create slide navigation
  "embedImages": true           // Embed images in HTML
}
```

**Requirements**:
- LibreOffice installed (same as existing transformers)

**Output**: Single HTML file with:
- CSS styling for slide layout
- Print button
- Navigation controls
- Embedded images (no external files needed)

---

## AI-Powered Transformers

### DocumentSummarizerTransformer

**Purpose**: Generate AI summaries of documents with key points extraction.

**Method Name**: `document_summarizer`

**Use Cases**:
- Document triage and quick review
- Email digests of long reports
- Content preview generation
- Executive summaries

**Parameters**:
```json
{
  "maxLength": 200,             // Max summary length (words)
  "format": "json",             // "json" or "text"
  "includeKeyPoints": true,     // Extract key points
  "language": "english"         // Target language
}
```

**JSON Output**:
```json
{
  "summary": "This document discusses the quarterly financial results...",
  "keyPoints": [
    "Revenue increased by 15% compared to last quarter",
    "Operating expenses decreased by 8%",
    "New product launch scheduled for Q2",
    "Customer satisfaction scores improved to 4.5/5",
    "International expansion plans announced"
  ],
  "metrics": {
    "summaryWordCount": 150,
    "sourceWordCount": 5000,
    "compressionRatio": 0.03,
    "sourceLength": 25000
  },
  "metadata": {
    "model": "ollama-llama3.2",
    "generatedAt": 1737500000000
  }
}
```

**Text Output**:
```
=== SUMMARY ===

This document discusses the quarterly financial results...

=== KEY POINTS ===

1. Revenue increased by 15% compared to last quarter
2. Operating expenses decreased by 8%
3. New product launch scheduled for Q2
...
```

---

### DocumentQATransformer

**Purpose**: Answer specific questions about document content using AI.

**Method Name**: `document_qa`

**Use Cases**:
- Automated document review
- Compliance checking ("Does this contract mention liability?")
- Information extraction ("What is the deadline mentioned?")
- Research assistance

**Parameters (Single Question)**:
```json
{
  "question": "What is the main topic of this document?",
  "format": "json"
}
```

**Parameters (Multiple Questions)**:
```json
{
  "questions": [
    "Who is the author of this document?",
    "What is the publication date?",
    "What are the main conclusions?",
    "Are there any recommendations?"
  ],
  "format": "json"
}
```

**JSON Output**:
```json
{
  "answers": {
    "Who is the author of this document?": "Dr. Sarah Johnson from MIT",
    "What is the publication date?": "January 15, 2026",
    "What are the main conclusions?": "The research concludes that...",
    "Are there any recommendations?": "The authors recommend three key actions..."
  },
  "metadata": {
    "questionCount": 4,
    "documentLength": 12500,
    "documentWordCount": 2300,
    "model": "ollama-llama3.2",
    "generatedAt": 1737500000000
  }
}
```

---

## Configuration

### Application Properties

```yaml
hitorro:
  # Enable AI services
  ai:
    enabled: true                     # Default: false
    ollama-url: http://localhost:11434
    model-name: llama3.2              # Chat model
    embedding-model: nomic-embed-text # Embedding model
    temperature: 0.7                  # 0.0-1.0 (higher = more creative)

  # Existing transformer config
  transformer:
    enabled: true
    libreoffice-path: /usr/bin/soffice  # For presentation transformer
```

### Dependencies

Add Spring AI to your project (in `hitorro-spring-boot-autoconfigure/pom.xml`):

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-ollama-spring-boot-starter</artifactId>
    <version>1.0.0-M4</version>
</dependency>
```

---

## Examples

### Example 1: Summarize a PDF Report

```java
// 1. Convert PDF to text (using existing PDFToTextTransformer)
TransformJobParameters pdfToText = TransformerUtil.createJobParameters(
    null,  // No constraint needed
    pdfContentGuid,
    documentGuid,
    "text/plain",
    true,  // Add as child
    null   // No parameters
);

// 2. Summarize the text
TransformJobParameters summarize = TransformerUtil.createJobParameters(
    null,
    textContentGuid,
    documentGuid,
    "application/json",
    true,
    "{\"maxLength\": 300, \"includeKeyPoints\": true}"
);
summarize.setTransformer("DocumentSummarizerTransformer");
summarize.setMethod("document_summarizer");
```

### Example 2: Extract Data from Excel

```java
TransformJobParameters excelToJson = TransformerUtil.createJobParameters(
    null,
    excelContentGuid,
    documentGuid,
    "application/json",
    true,
    "{\"sheetName\": \"Sales Data\", \"format\": \"ndjson\"}"
);
excelToJson.setTransformer("SpreadsheetToJSONTransformer");
excelToJson.setMethod("spreadsheet_to_json");
```

### Example 3: Ask Questions About a Contract

```java
// First convert document to text if needed
// Then ask questions
String questions = """
{
  "questions": [
    "What is the contract duration?",
    "What is the termination notice period?",
    "Are there any liability limitations?",
    "What is the governing law?"
  ],
  "format": "json"
}
""";

TransformJobParameters qa = TransformerUtil.createJobParameters(
    null,
    textContentGuid,
    documentGuid,
    "application/json",
    true,
    questions
);
qa.setTransformer("DocumentQATransformer");
qa.setMethod("document_qa");
```

### Example 4: REST API Usage

```bash
# Summarize a document via REST API
curl -X POST http://localhost:8080/api/transformer/queue \
  -H "Content-Type: application/json" \
  -d '{
    "documentGuid": "30:4bd9f:6e",
    "contentGuid": "02:4bd9f:6f",
    "targetMimeType": "application/json",
    "addAsChild": true,
    "parameters": "{\"maxLength\": 200, \"includeKeyPoints\": true}",
    "executeImmediately": true
  }'
```

---

## Troubleshooting

### AI Service Not Available

**Error**: `AI service not available. Enable with hitorro.ai.enabled=true`

**Solutions**:
1. Check Ollama is running: `curl http://localhost:11434`
2. Verify model is pulled: `ollama list`
3. Check application.yml has `hitorro.ai.enabled: true`
4. Check logs for AI service initialization

### Ollama Connection Failed

**Error**: `Failed to connect to Ollama at http://localhost:11434`

**Solutions**:
1. Start Ollama: `ollama serve`
2. Check firewall/ports
3. Update `ollama-url` if running on different host

### Model Not Found

**Error**: `Model llama3.2 not found`

**Solutions**:
```bash
ollama pull llama3.2
ollama pull nomic-embed-text
```

### LibreOffice Not Found

**Error**: `LibreOffice not available`

**Solutions**:
1. Install LibreOffice: `brew install --cask libreoffice`
2. Set path in application.yml:
   ```yaml
   hitorro:
     transformer:
       libreoffice-path: /Applications/LibreOffice.app/Contents/MacOS/soffice
   ```

---

## Performance Tips

### AI Transformers

- **Chunk large documents**: Documents over 10,000 words should be chunked for better results
- **Adjust temperature**: Lower (0.3-0.5) for factual extraction, higher (0.7-0.9) for creative summaries
- **Use batch Q&A**: Ask multiple questions at once for efficiency
- **Cache results**: AI generation is expensive - cache summaries and answers

### Spreadsheet Transformer

- **Large files**: Consider streaming for files over 10MB
- **NDJSON format**: Use for very large datasets (millions of rows)
- **Selective sheets**: Only process needed sheets with `sheetName` parameter

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Hitorro Transformer Framework          │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
┌────────v────────┐    ┌─────────v──────────┐
│  Non-AI         │    │  AI-Powered        │
│  Transformers   │    │  Transformers      │
│                 │    │                    │
│  - Embedding    │    │  - Summarizer      │
│    Preprocessor │    │  - Q&A             │
│  - Spreadsheet  │    │                    │
│    to JSON      │    │  Uses AIService    │
│  - Presentation │    │  via Registry      │
│    to HTML      │    │                    │
└─────────────────┘    └──────────┬─────────┘
                                  │
                       ┌──────────v─────────┐
                       │   AIServiceRegistry │
                       └──────────┬─────────┘
                                  │
                       ┌──────────v─────────┐
                       │  OllamaAIService   │
                       │  (Spring AI)       │
                       └──────────┬─────────┘
                                  │
                       ┌──────────v─────────┐
                       │    Ollama Server   │
                       │   (localhost:11434)│
                       │                    │
                       │  Models:           │
                       │  - llama3.2        │
                       │  - nomic-embed-text│
                       └────────────────────┘
```

---

## Next Steps

1. **Install Ollama** and pull models
2. **Enable AI service** in application.yml
3. **Run tests** to verify transformers work
4. **Try examples** with your documents
5. **Monitor performance** and adjust settings

For more examples, see the test suite in `TransformerTemplateRESTIntegrationTest.java`.
