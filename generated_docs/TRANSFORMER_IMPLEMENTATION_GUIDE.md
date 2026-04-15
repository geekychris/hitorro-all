# Hitorro Transformer Framework - Implementation Guide

## Overview

The Hitorro Transformer framework provides a flexible system for converting content renditions between different formats. It supports automatic format detection, job queuing, and extensible transformation methods.

## What's Been Implemented

### 1. Transformer Implementations

Three new transformer methods have been added:

#### **PDFToImageTransformer**
- **Method Name**: `pdf_to_image`
- **Capabilities**: Converts PDF documents to images (JPEG, PNG, TIFF)
- **Dependencies**: `pdftoppm` (poppler-utils package)
- **Parameters**:
  - `format`: Output format (jpeg, png, tiff)
  - `dpi`: Resolution (default: 150)
  - `quality`: JPEG quality 1-100 (default: 85)
  - `page`: Page number to convert (default: 1)
- **Location**: `hitorro-basedms/src/main/java/com/hitorro/basedms/transformer/methods/PDFToImageTransformer.java`

#### **LibreOfficeTransformer**
- **Method Name**: `libreoffice_convert`
- **Capabilities**: Converts office documents to PDF
  - Microsoft Word (.doc, .docx) → PDF
  - Excel (.xls, .xlsx) → PDF
  - PowerPoint (.ppt, .pptx) → PDF
  - OpenDocument (.odt, .ods, .odp) → PDF
- **Dependencies**: LibreOffice/OpenOffice (`soffice` executable)
- **Parameters**:
  - `format`: Output format (default: pdf)
- **Location**: `hitorro-basedms/src/main/java/com/hitorro/basedms/transformer/methods/LibreOfficeTransformer.java`

#### **ImageMagickTransformer**
- **Method Name**: `imagemagick_convert`
- **Capabilities**: Image format conversion and manipulation
- **Dependencies**: ImageMagick (`convert` command)
- **Parameters**:
  - `format`: Output format (jpg, png, etc.)
  - `width`: Target width in pixels
  - `height`: Target height in pixels
  - `quality`: Quality for lossy formats
  - `resize`: Percentage or geometry (e.g., "50%", "800x600")
- **Location**: `hitorro-basedms/src/main/java/com/hitorro/basedms/transformer/methods/ImageMagickTransformer.java`

### 2. Configuration

Updated `data/transcoder/edges.csv` with new transformation edges:

```csv
MimeFrom,MimeTo,Transformer,Method,MethodArgs
application/pdf, image/jpeg, pdf_converter, pdf_to_image, "format=jpeg,dpi=150,quality=85"
application/pdf, image/png, pdf_converter, pdf_to_image, "format=png,dpi=150"
application/msword, application/pdf, libreoffice, libreoffice_convert, format=pdf
application/vnd.openxmlformats-officedocument.wordprocessingml.document, application/pdf, libreoffice, libreoffice_convert, format=pdf
...and more
```

### 3. Helper Utilities

**RenditionTransformationHelper** class provides:
- `getAvailableTargetMimeTypes(sourceMimeType)` - Get all possible target formats
- `getAvailableTransformations(sourceMimeType)` - Get detailed transformation info
- `isTransformationAvailable(source, target)` - Check if conversion is possible
- `getConversionEdge(source, target)` - Get the conversion edge for a transformation

**Location**: `hitorro-basedms/src/main/java/com/hitorro/basedms/transformer/RenditionTransformationHelper.java`

### 4. REST API

**RenditionTransformationController** provides the following endpoints:

#### Get Available Target Formats
```http
GET /api/transformer/available-targets?sourceMimeType=application/pdf

Response:
{
  "sourceMimeType": "application/pdf",
  "availableTargets": ["image/jpeg", "image/png"],
  "count": 2
}
```

#### Get All Transformations for a MIME Type
```http
GET /api/transformer/transformations?sourceMimeType=application/pdf

Response:
{
  "sourceMimeType": "application/pdf",
  "transformations": [
    {
      "targetMimeType": "image/jpeg",
      "methodName": "pdf_to_image",
      "methodArgs": "format=jpeg,dpi=150,quality=85",
      "available": true
    }
  ],
  "count": 1
}
```

#### Get Available Transformations for Content
```http
GET /api/transformer/content/{contentGuid}/available-transformations

Response:
{
  "contentGuid": "Content:123",
  "sourceMimeType": "application/pdf",
  "transformations": [...],
  "count": 2
}
```

#### Queue a Transformation Job
```http
POST /api/transformer/queue
Content-Type: application/json

{
  "documentGuid": "Document:123",
  "contentGuid": "Content:456",
  "targetMimeType": "image/jpeg",
  "tagDomain": "rendition",
  "tagValue": "preview",
  "targetFileName": "preview_image",
  "addAsChild": true
}

Response:
{
  "success": true,
  "jobId": "1234567890_1",
  "jobGuid": "PersistedSerializedObject:789",
  "documentGuid": "Document:123",
  "sourceMimeType": "application/pdf",
  "targetMimeType": "image/jpeg",
  "status": "queued"
}
```

**Location**: `hitorro-spring-boot/hitorro-spring-boot-autoconfigure/src/main/java/com/hitorro/spring/autoconfigure/transformer/RenditionTransformationController.java`

## Installation & Setup

### 1. Install System Dependencies

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y poppler-utils libreoffice imagemagick
```

#### macOS:
```bash
brew install poppler libreoffice imagemagick
```

#### RHEL/CentOS:
```bash
sudo yum install -y poppler-utils libreoffice ImageMagick
```

### 2. Configure Paths (Optional)

Add to your application properties if the executables are not in PATH:

```properties
# PDF to Image transformer
transformer.pdftoppm.path=/usr/bin/pdftoppm
transformer.pdf.image.dpi=150
transformer.pdf.image.quality=85

# LibreOffice transformer
transformer.libreoffice.path=/usr/bin/soffice

# ImageMagick transformer
transformer.imagemagick.path=/usr/bin/convert

# Enable transformer REST API (default: true)
hitorro.transformer.enabled=true
hitorro.transformer.rest.enabled=true
```

### 3. Configure Transformation Edges

The edges.csv file defines available transformations. Edit `${HT_BIN}/data/transcoder/edges.csv`:

```csv
MimeFrom,MimeTo,Transformer,Method,MethodArgs
application/pdf,image/jpeg,pdf_converter,pdf_to_image,"format=jpeg,dpi=150,quality=85"
```

- **MimeFrom**: Source MIME type (use `*` for wildcard)
- **MimeTo**: Target MIME type
- **Transformer**: Logical name (for grouping)
- **Method**: Registered method name
- **MethodArgs**: Comma-separated parameters

## Usage Examples

### From the UI (Conceptual)

When viewing a document with a PDF content rendition:

1. User selects the PDF rendition
2. UI calls `/api/transformer/content/{contentGuid}/available-transformations`
3. UI displays available formats (JPEG, PNG)
4. User selects "Convert to JPEG Preview"
5. UI posts to `/api/transformer/queue`:
   ```json
   {
     "documentGuid": "Document:123",
     "contentGuid": "Content:456",
     "targetMimeType": "image/jpeg",
     "tagDomain": "rendition",
     "tagValue": "preview",
     "targetFileName": "preview",
     "addAsChild": true
   }
   ```
6. Job is queued and processed asynchronously
7. New JPEG rendition is added as a child of the original PDF content

### Programmatic Usage

```java
// Check if transformation is available
boolean canConvert = RenditionTransformationHelper.isTransformationAvailable(
    "application/pdf", "image/jpeg");

// Get all available target formats
List<String> targets = RenditionTransformationHelper.getAvailableTargetMimeTypes(
    "application/pdf");

// Queue a transformation job
DMSSession session = DMSSessionFactory.getFactory().getSession();
try {
    MimeTypeContentConstraint constraint = new MimeTypeContentConstraint("application/pdf");
    
    HTPredicate<ConvertionEdge> edgeConstraint = new LogicalAndOperator<>(
        new FromConstraint("application/pdf"),
        new ToConstraint("image/jpeg")
    );
    
    TransformJobParameters params = TransformerUtil.createJobParameters(
        null,                           // notification guid
        null,                           // notification state
        constraint,                     // content constraint
        "Document:123",                 // document guid
        edgeConstraint,                 // conversion edge constraint
        "rendition",                    // tag domain
        "preview",                      // tag value
        "preview_image",                // target filename
        true                            // add as child
    );
    
    PersistedSerializedObject job = TransformerUtil.queueTransformJob(
        params, session, true);
        
    System.out.println("Job queued: " + job.getGuid());
} finally {
    DMSSessionFactory.closeSession(session);
}
```

## Architecture

### Job Queue Processing

1. **TransformJob** extends `Job` and handles the transformation execution
2. **TransformJobParameters** contains all parameters for the job
3. **TransformerService** maintains a job queue using `GroupSpacedPSOQueueProcessor`
4. Jobs are persisted to the database in `PersistedSerializedObject.CollectionID_TranscoderQueue`
5. Worker threads process jobs asynchronously

### Method Registration

On service initialization, `TransformerService.registerTransformMethods()`:
1. Instantiates each transformer implementation
2. Checks if the transformer's dependencies are available (`ensureServiceAvailable()`)
3. Registers available transformers in the method registry
4. Logs which transformers are available/unavailable

### Conversion Process

1. User/API queues transformation job
2. Job parameters specify source content, target format, and output settings
3. `TransformJob.doAction()` executes:
   - Fetches source content from database
   - Gets content file from storage
   - Calls transformer method's `convert()`
   - Saves resulting file using `ContentSetter`
   - Links new content to parent document
4. Job completes and rendition is available

## Adding New Transformers

To add a new transformer:

### 1. Create Transformer Class

```java
package com.hitorro.basedms.transformer.methods;

import com.hitorro.basedms.transformer.TransformMethod;
import com.hitorro.util.basefile.fs.BaseFile;
import java.io.IOException;

public class MyTransformer implements TransformMethod {
    public static String METHOD_NAME = "my_transformer";
    
    @Override
    public String getMethodName() {
        return METHOD_NAME;
    }
    
    @Override
    public boolean ensureServiceAvailable() {
        // Check if dependencies are available
        return true;
    }
    
    @Override
    public BaseFile convert(BaseFile sourceFile, String id, String parameters, 
                           String notifyGuid, int maxWaitTimeMinutes) 
            throws IOException {
        // Implement conversion logic
        // Return output file as BaseFile
    }
}
```

### 2. Register in TransformerService

Add to `registerTransformMethods()`:

```java
MyTransformer myTransformer = new MyTransformer();
if (myTransformer.ensureServiceAvailable()) {
    setMethod(myTransformer);
    Log.transformer.info("Registered transformer method: %s", 
        myTransformer.getMethodName());
}
```

### 3. Add Edges to Configuration

Add entries to `data/transcoder/edges.csv`:

```csv
source/mimetype,target/mimetype,transformer,my_transformer,"param1=value1,param2=value2"
```

## Future Enhancements

- **Multi-step transformations**: Chain multiple transformers (mentioned in user request)
- **Progress tracking**: Real-time status updates for long-running jobs
- **Batch processing**: Queue multiple transformations at once
- **UI components**: React/Vue components for rendition management
- **Webhook notifications**: Notify external systems when transformations complete
- **Retry logic**: Automatic retry on transient failures
- **Transformation presets**: Pre-configured transformation sets (e.g., "Create all web renditions")

## Troubleshooting

### Transformer Not Available

**Problem**: Transformation shows as unavailable
**Solutions**:
- Verify system dependency is installed: `which pdftoppm`, `which soffice`, etc.
- Check path configuration in application properties
- Review logs for specific error messages

### Job Not Processing

**Problem**: Queued jobs remain in queue
**Solutions**:
- Verify TransformerService is initialized
- Check job queue threads are running
- Review `DumpWorkflowTranscodeQueue` debug command output
- Check database for persisted jobs

### Conversion Fails

**Problem**: Job completes but conversion fails
**Solutions**:
- Check job execution logs
- Verify source file exists and is readable
- Test transformer command-line tool directly
- Check disk space and permissions

## Debug Commands

The framework provides debug commands for troubleshooting:

- `DumpWorkflowTranscodeQueue`: Show queued transformation jobs
- `DumpWorkflowTranscodeCurrent`: Show currently processing jobs

## API Testing with curl

```bash
# Get available transformations for PDF
curl "http://localhost:8080/api/transformer/transformations?sourceMimeType=application/pdf"

# Get transformations for specific content
curl "http://localhost:8080/api/transformer/content/Content:123/available-transformations"

# Queue a transformation
curl -X POST http://localhost:8080/api/transformer/queue \
  -H "Content-Type: application/json" \
  -d '{
    "documentGuid": "Document:123",
    "contentGuid": "Content:456",
    "targetMimeType": "image/jpeg",
    "tagDomain": "rendition",
    "tagValue": "preview",
    "addAsChild": true
  }'
```

---

**Implementation Date**: January 2026  
**Framework Version**: Compatible with Hitorro Spring Boot integration  
**Status**: Production Ready
