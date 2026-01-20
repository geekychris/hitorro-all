# Hitorro Transformer - Quick Start Guide

Get up and running with content transformation in under 5 minutes!

## 🎯 Two Ways to Use

1. **React UI** (Easiest) - Integrated into the Document Management page at `http://localhost:3000`
2. **REST API** - Programmatic access for custom integrations

## Prerequisites

- Java 11 or higher
- Hitorro DMS with Spring Boot
- System access to install packages (sudo/admin rights)

## Step 1: Install Dependencies

Choose your platform and run the installation script:

### Automated Installation (Recommended)

```bash
cd hitorro
./scripts/install-transformer-dependencies.sh
```

This script will automatically:
- Detect your operating system
- Install poppler-utils (pdftoppm)
- Install LibreOffice
- Install ImageMagick
- Verify all installations

### Manual Installation

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y poppler-utils libreoffice imagemagick
```

#### macOS (requires Homebrew)
```bash
brew install poppler libreoffice imagemagick
```

#### RHEL/CentOS/Fedora
```bash
sudo yum install -y poppler-utils libreoffice ImageMagick
# or on newer systems:
sudo dnf install -y poppler-utils libreoffice ImageMagick
```

#### Windows
1. **Poppler**: Download from https://github.com/oschwartz10612/poppler-windows/releases/
2. **LibreOffice**: Download from https://www.libreoffice.org/download/
3. **ImageMagick**: Download from https://imagemagick.org/script/download.php

Add all executables to your system PATH.

## Step 2: Verify Installation

Run the test script to verify everything is working:

```bash
./scripts/test-transformer-setup.sh
```

You should see:
```
Testing pdftoppm (PDF to Image)... ✓ PASS
Testing LibreOffice (Document to PDF)... ✓ PASS
Testing ImageMagick (Image Conversion)... ✓ PASS
```

## Step 3: Configure Hitorro (Optional)

If the executables are not in your PATH, add to `application.properties`:

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

## Step 4: Start Your Application

```bash
cd hitorro-example-springboot
./mvnw spring-boot:run
```

Or if using the standalone start script:
```bash
./start-backend.sh
```

## Step 5: Use the Transformer

### Option A: React UI (Recommended for Getting Started)

Open your browser and navigate to:
```
http://localhost:3000
```

The transformer is **integrated into the Document Management page**:

1. Click **"Document Management"** tab (default view)
2. Select any document with content
3. Click the purple **"Transform"** button next to a content item
4. Choose your desired transformation format
5. Confirm to queue the job

The transformed content will be added as a new rendition when processing completes.

See **[TRANSFORMER_UI_INTEGRATION_COMPLETE.md](../TRANSFORMER_UI_INTEGRATION_COMPLETE.md)** for detailed usage.

### Option B: REST API (For Developers)

#### Check Available Transformations

```bash
# Get transformations for PDF
curl "http://localhost:8080/api/transformer/transformations?sourceMimeType=application/pdf"
```

Expected response:
```json
{
  "sourceMimeType": "application/pdf",
  "transformations": [
    {
      "targetMimeType": "image/jpeg",
      "methodName": "pdf_to_image",
      "methodArgs": "format=jpeg,dpi=150,quality=85",
      "available": true
    },
    {
      "targetMimeType": "image/png",
      "methodName": "pdf_to_image",
      "methodArgs": "format=png,dpi=150",
      "available": true
    }
  ],
  "count": 2
}
```

### Queue a Transformation

```bash
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

Expected response:
```json
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

## Step 6: Run Tests

Run the unit tests to verify functionality:

```bash
# Run transformer unit tests
cd hitorro-basedms
../mvnw test -Dtest=PDFToImageTransformerTest
../mvnw test -Dtest=LibreOfficeTransformerTest
../mvnw test -Dtest=ImageMagickTransformerTest

# Run integration tests
cd ../hitorro-example-springboot
../mvnw test -Dtest=TransformerRestApiIntegrationTest
```

## Common Use Cases

### 1. Convert PDF to Preview Image

Perfect for generating thumbnails:

```bash
curl -X POST http://localhost:8080/api/transformer/queue \
  -H "Content-Type: application/json" \
  -d '{
    "documentGuid": "Document:123",
    "sourceMimeType": "application/pdf",
    "targetMimeType": "image/jpeg",
    "tagDomain": "rendition",
    "tagValue": "thumbnail",
    "targetFileName": "thumbnail",
    "addAsChild": true
  }'
```

### 2. Convert Word Document to PDF

```bash
curl -X POST http://localhost:8080/api/transformer/queue \
  -H "Content-Type: application/json" \
  -d '{
    "documentGuid": "Document:456",
    "sourceMimeType": "application/msword",
    "targetMimeType": "application/pdf",
    "tagDomain": "rendition",
    "tagValue": "pdf_version",
    "addAsChild": true
  }'
```

### 3. Resize Image

```bash
# Edit edges.csv to add custom parameters, or use ImageMagick directly
# The framework supports custom parameters per transformation
```

## Supported Transformations

### PDF Conversions
- PDF → JPEG (with DPI and quality control)
- PDF → PNG (high quality)
- PDF → TIFF (archival)

### Office Document Conversions
- Word (.doc, .docx) → PDF
- Excel (.xls, .xlsx) → PDF
- PowerPoint (.ppt, .pptx) → PDF
- OpenDocument (.odt, .ods, .odp) → PDF

### Image Conversions
- Any image format → JPEG
- Any image format → PNG
- Image resizing (width, height, percentage)
- Quality adjustment for lossy formats

## Troubleshooting

### Issue: "Transformer not available"

**Solution**: Verify the tool is installed and in PATH:
```bash
which pdftoppm
which soffice
which convert
```

### Issue: "Job queued but not processing"

**Solution**: Check if the TransformerService is running:
```bash
# Check logs for:
# "Registered transformer method: pdf_to_image"
# "Registered transformer method: libreoffice_convert"
# "Registered transformer method: imagemagick_convert"
```

### Issue: "Conversion fails with timeout"

**Solution**: LibreOffice first-run may take longer. Increase timeout or pre-initialize:
```bash
soffice --headless --invisible --accept="socket,host=localhost,port=2002;urp;" &
# Wait a few seconds
pkill soffice
```

### Issue: Tests fail with "command not found"

**Solution**: The test tools check for system commands. If not available, tests will be skipped.
Install the missing dependencies using the installation script.

## Configuration Files

### edges.csv

Located at: `data/transcoder/edges.csv`

Format:
```csv
MimeFrom,MimeTo,Transformer,Method,MethodArgs
application/pdf,image/jpeg,pdf_converter,pdf_to_image,"format=jpeg,dpi=150,quality=85"
```

You can add custom transformations by editing this file.

### Application Properties

Optional configuration in `application.properties`:

```properties
# Transformer thread pool
transcoder.threads=2

# Enable statistics
hibernate.enablestats=false

# Database (if using custom)
db.embedded.name=hitorrodb

# Transformer service
transformer.enabled=true
```

## Performance Tips

1. **Adjust DPI**: Lower DPI = faster conversion, smaller files
   - Thumbnails: 72-96 DPI
   - Preview: 150 DPI
   - Print: 300 DPI

2. **JPEG Quality**: Balance quality vs file size
   - Web preview: 75-85
   - High quality: 90-95
   - Maximum: 95-100

3. **Thread Pool**: Increase `transcoder.threads` for parallel processing
   - Default: 2 threads
   - Recommended: Number of CPU cores / 2

4. **Batch Processing**: Queue multiple jobs at once
   - They will be processed in parallel up to thread limit

## Next Steps

- **Add Custom Transformers**: See `TRANSFORMER_IMPLEMENTATION_GUIDE.md`
- **Multi-step Transformations**: Chain transformations (coming soon)
- **UI Integration**: Build UI components for your needs
- **Webhooks**: Get notifications when transformations complete
- **Monitoring**: Track transformation success rates and performance

## Support & Documentation

- **Web UI Guide**: `TRANSFORMER_UI_GUIDE.md` - How to use the web interface
- **Full Documentation**: `TRANSFORMER_IMPLEMENTATION_GUIDE.md` - Technical details
- **API Reference**: Test with `curl` examples above
- **Test Scripts**: `scripts/test-transformer-setup.sh`
- **Installation**: `scripts/install-transformer-dependencies.sh`

## Quick Reference

### REST API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/transformer/available-targets` | GET | List target formats |
| `/api/transformer/transformations` | GET | Get all transformations |
| `/api/transformer/content/{guid}/available-transformations` | GET | Get content options |
| `/api/transformer/queue` | POST | Queue transformation |

### Command Line Tools

```bash
# Test individual tools
pdftoppm -jpeg -r 150 input.pdf output
soffice --headless --convert-to pdf document.docx
convert input.png -resize 50% output.jpg

# Run setup tests
./scripts/test-transformer-setup.sh

# Install dependencies
./scripts/install-transformer-dependencies.sh
```

---

**Ready to transform!** 🚀

For detailed implementation guide and advanced features, see `TRANSFORMER_IMPLEMENTATION_GUIDE.md`.
