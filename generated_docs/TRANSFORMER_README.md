# Hitorro Content Transformation Framework

A powerful, extensible framework for converting content between formats with queued job processing and REST API integration.

## 🎯 What It Does

Transform content renditions on-demand or through scheduled jobs:
- **PDF → Images** (JPEG, PNG, TIFF) with customizable DPI and quality
- **Office Docs → PDF** (Word, Excel, PowerPoint, OpenDocument formats)
- **Image Conversions** with resizing, format changes, and quality control
- **Extensible Architecture** - easily add new transformation methods

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[TRANSFORMER_QUICK_START.md](TRANSFORMER_QUICK_START.md)** | Get started in 5 minutes |
| **[TRANSFORMER_IMPLEMENTATION_GUIDE.md](TRANSFORMER_IMPLEMENTATION_GUIDE.md)** | Complete technical guide |
| This README | Overview and reference |

## 🚀 Quick Setup

### 1. Install Dependencies (One Command)

```bash
./scripts/install-transformer-dependencies.sh
```

This installs:
- **poppler-utils** (pdftoppm) - PDF to image conversion
- **LibreOffice** - Office document conversion
- **ImageMagick** - Image manipulation

### 2. Verify Installation

```bash
./scripts/test-transformer-setup.sh
```

### 3. Start Application

```bash
./start-backend.sh
# or
cd hitorro-example-springboot && ./mvnw spring-boot:run
```

### 4. Test It

```bash
curl "http://localhost:8080/api/transformer/transformations?sourceMimeType=application/pdf"
```

## 📋 Features

### Transformer Methods

| Method | Input | Output | Tool |
|--------|-------|--------|------|
| `pdf_to_image` | PDF | JPEG/PNG/TIFF | pdftoppm |
| `libreoffice_convert` | Office Docs | PDF | LibreOffice |
| `imagemagick_convert` | Images | Any Image Format | ImageMagick |

### Supported Conversions

**PDF Conversions:**
- application/pdf → image/jpeg
- application/pdf → image/png

**Office to PDF:**
- application/msword → application/pdf
- application/vnd.openxmlformats-officedocument.* → application/pdf
- application/vnd.oasis.opendocument.* → application/pdf

**Image Conversions:**
- Any image format → JPEG/PNG
- Resize, quality adjustment, format conversion

## 🔌 REST API

### Get Available Transformations

```bash
GET /api/transformer/transformations?sourceMimeType={mimeType}
```

### Get Transformations for Content

```bash
GET /api/transformer/content/{contentGuid}/available-transformations
```

### Queue Transformation Job

```bash
POST /api/transformer/queue
Content-Type: application/json

{
  "documentGuid": "Document:123",
  "contentGuid": "Content:456",
  "targetMimeType": "image/jpeg",
  "tagDomain": "rendition",
  "tagValue": "preview",
  "addAsChild": true
}
```

## 🧪 Testing

### Unit Tests

```bash
cd hitorro-basedms
../mvnw test -Dtest=PDFToImageTransformerTest
../mvnw test -Dtest=LibreOfficeTransformerTest
../mvnw test -Dtest=ImageMagickTransformerTest
```

### Integration Tests

```bash
cd hitorro-example-springboot
../mvnw test -Dtest=TransformerRestApiIntegrationTest
```

### Create Test Data

```bash
./scripts/create-test-documents.sh
```

## ⚙️ Configuration

### Optional Properties

Add to `application.properties` if tools are not in PATH:

```properties
# Tool paths
transformer.pdftoppm.path=/usr/bin/pdftoppm
transformer.libreoffice.path=/usr/bin/soffice
transformer.imagemagick.path=/usr/bin/convert

# PDF to Image defaults
transformer.pdf.image.dpi=150
transformer.pdf.image.quality=85

# Job processing
transcoder.threads=2

# Enable/disable
hitorro.transformer.enabled=true
hitorro.transformer.rest.enabled=true
```

### Transformation Edges

Edit `data/transcoder/edges.csv` to customize transformations:

```csv
MimeFrom,MimeTo,Transformer,Method,MethodArgs
application/pdf,image/jpeg,pdf_converter,pdf_to_image,"format=jpeg,dpi=150,quality=85"
```

## 🏗️ Architecture

```
┌─────────────┐
│  REST API   │ ← User/UI queues transformation
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ TransformJob Queue  │ ← Persisted to database
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Worker Threads     │ ← Process jobs asynchronously
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Transform Methods   │ ← PDFToImage, LibreOffice, ImageMagick
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│   New Rendition     │ ← Stored as Content object
└─────────────────────┘
```

## 📁 Project Structure

```
hitorro/
├── hitorro-basedms/
│   └── src/main/java/com/hitorro/basedms/transformer/
│       ├── TransformerService.java          # Main service
│       ├── TransformJob.java                # Job executor
│       ├── TransformJobParameters.java      # Job parameters
│       ├── RenditionTransformationHelper.java # Helper utilities
│       └── methods/                          # Transformer implementations
│           ├── PDFToImageTransformer.java
│           ├── LibreOfficeTransformer.java
│           └── ImageMagickTransformer.java
├── hitorro-spring-boot/
│   └── .../transformer/
│       ├── RenditionTransformationController.java  # REST API
│       └── TransformerAutoConfiguration.java       # Auto-config
├── scripts/
│   ├── install-transformer-dependencies.sh  # Installer
│   ├── test-transformer-setup.sh            # Verification
│   └── create-test-documents.sh             # Test data
└── data/transcoder/
    └── edges.csv                             # Transformation config
```

## 🔧 Troubleshooting

### Problem: Transformer not available

**Check installation:**
```bash
which pdftoppm soffice convert
```

**Reinstall:**
```bash
./scripts/install-transformer-dependencies.sh
```

### Problem: Job not processing

**Check logs for:**
```
Registered transformer method: pdf_to_image
Registered transformer method: libreoffice_convert
```

**Verify TransformerService is running**

### Problem: Conversion fails

**Check tool directly:**
```bash
pdftoppm -v
soffice --version
convert -version
```

**Review job execution logs**

## 🎓 Learn More

### Adding Custom Transformers

See `TRANSFORMER_IMPLEMENTATION_GUIDE.md` section "Adding New Transformers"

### Integration Patterns

```java
// Programmatic usage
RenditionTransformationHelper.isTransformationAvailable(
    "application/pdf", "image/jpeg");

// Queue job
TransformJobParameters params = TransformerUtil.createJobParameters(...);
PersistedSerializedObject job = TransformerUtil.queueTransformJob(params, session, true);
```

### UI Integration

The REST API is designed for easy UI integration:

1. User selects content rendition
2. UI fetches available transformations
3. User chooses target format
4. UI posts to `/api/transformer/queue`
5. Job processes asynchronously
6. New rendition appears in document

## 📊 Performance

### Benchmarks (Approximate)

| Operation | Size | Time | Notes |
|-----------|------|------|-------|
| PDF → JPEG (150 DPI) | 1 page | ~1s | Single page |
| Word → PDF | 10 pages | ~3-5s | First run slower |
| Image Resize | 2MB | ~0.5s | 50% reduction |

### Optimization Tips

- Lower DPI for faster conversions (72-96 for web)
- Adjust `transcoder.threads` based on CPU cores
- Use JPEG for photos, PNG for diagrams
- Queue batch jobs for better throughput

## 🛡️ Production Considerations

- **Error Handling**: Jobs log failures, don't crash system
- **Disk Space**: Monitor temp directory usage
- **Thread Pool**: Adjust based on server capacity
- **Timeouts**: Configure for large documents
- **Security**: Validate file types and sizes

## 📝 License

Copyright (c) 2006-2025 Chris Collins - MIT License

## 🤝 Contributing

To add a new transformer:

1. Implement `TransformMethod` interface
2. Register in `TransformerService.registerTransformMethods()`
3. Add edges to `edges.csv`
4. Write tests
5. Update documentation

## 📞 Support

- **Issues**: Check troubleshooting section
- **Questions**: See implementation guide
- **Testing**: Run test scripts

---

**Ready to transform!** Start with `TRANSFORMER_QUICK_START.md` 🚀
