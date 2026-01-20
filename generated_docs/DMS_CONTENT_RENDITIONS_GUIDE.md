# DMS Content Management & Renditions Guide

## Overview

I've implemented comprehensive content management and rendition support for the Hitorro DMS, including:
- ✅ **Content upload** with rendition type specification
- ✅ **Multiple renditions** per document (original, thumbnails, previews, PDFs, etc.)
- ✅ **Secondary renditions** (renditions derived from other content)
- ✅ **Document versioning** with content preservation
- ✅ **Content download** with proper file handling

## New Endpoints

### 1. Upload Content with Rendition Type
**POST** `/api/dms/documents/{id}/content`

Upload a file to a document, optionally specifying the rendition type.

**Request:**
- `file`: MultipartFile (the content to upload)
- `rendition`: String (optional) - rendition type ("original", "thumbnail", "preview", "pdf", etc.)

**Example:**
```bash
curl -X POST "http://localhost:8080/api/dms/documents/1/content" \
  -F "file=@document.pdf" \
  -F "rendition=original"
```

**Response:**
```json
{
  "status": "success",
  "message": "Content uploaded successfully",
  "contentId": 42,
  "fileName": "document.pdf",
  "size": 1048576,
  "rendition": "original"
}
```

### 2. Create Secondary Rendition
**POST** `/api/dms/documents/{documentId}/content/{contentId}/renditions`

Create a new rendition derived from existing content.

**Request:**
- `file`: MultipartFile (the rendition file)
- `renditionType`: String (required) - type of rendition ("thumbnail", "preview", "pdf", etc.)

**Example:**
```bash
# Create a thumbnail from the original image
curl -X POST "http://localhost:8080/api/dms/documents/1/content/42/renditions" \
  -F "file=@thumbnail.jpg" \
  -F "renditionType=thumbnail"
```

**Response:**
```json
{
  "status": "success",
  "message": "Rendition created successfully",
  "renditionId": 43,
  "sourceContentId": 42,
  "renditionType": "thumbnail",
  "fileName": "thumbnail.jpg",
  "size": 15360
}
```

### 3. List Renditions
**GET** `/api/dms/documents/{documentId}/content/{contentId}/renditions`

List all renditions derived from a specific content.

**Example:**
```bash
curl "http://localhost:8080/api/dms/documents/1/content/42/renditions"
```

**Response:**
```json
[
  {
    "id": 43,
    "originalFileName": "thumbnail.jpg",
    "contentSize": 15360,
    "storeName": "thumbnail",
    "creationDate": "2025-01-18T10:30:00",
    "parentRenditionId": 42,
    "renditionCount": 0
  },
  {
    "id": 44,
    "originalFileName": "preview.jpg",
    "contentSize": 102400,
    "storeName": "preview",
    "creationDate": "2025-01-18T10:31:00",
    "parentRenditionId": 42,
    "renditionCount": 0
  }
]
```

### 4. Download Specific Content
**GET** `/api/dms/documents/{documentId}/content/{contentId}/download`

Download a specific content/rendition by ID.

**Example:**
```bash
curl "http://localhost:8080/api/dms/documents/1/content/42/download" \
  --output original.pdf
```

### 5. Download First Content
**GET** `/api/dms/documents/{documentId}/content/download`

Download the first content from a document (convenience endpoint).

**Example:**
```bash
curl "http://localhost:8080/api/dms/documents/1/content/download" \
  --output document.pdf
```

### 6. List All Content
**GET** `/api/dms/documents/{id}/content/list`

List all content items for a document.

**Example:**
```bash
curl "http://localhost:8080/api/dms/documents/1/content/list"
```

**Response:**
```json
[
  {
    "id": 42,
    "originalFileName": "document.pdf",
    "contentSize": 1048576,
    "storeName": "original",
    "creationDate": "2025-01-18T10:00:00",
    "parentRenditionId": null,
    "renditionCount": 2
  }
]
```

### 7. Create Document Version
**POST** `/api/dms/documents/{id}/version`

Create a new minor version of a document.

**Request:**
```json
{
  "note": "Updated with new content"
}
```

**Example:**
```bash
curl -X POST "http://localhost:8080/api/dms/documents/1/version" \
  -H "Content-Type: application/json" \
  -d '{"note": "Version 1.1 - Added appendix"}'
```

**Response:**
```json
{
  "id": 2,
  "guid": "abc-def-ghi",
  "title": "My Document",
  "versionLabel": "1.1",
  "canonicalId": 1,
  "parentVersionId": 1,
  "contentCount": 0
}
```

## Use Cases

### Use Case 1: Image with Multiple Renditions

```bash
# 1. Create document
DOC_ID=$(curl -X POST "http://localhost:8080/api/dms/documents" \
  -H "Content-Type: application/json" \
  -d '{"title":"Photo Gallery Image"}' | jq -r '.id')

# 2. Upload original image
CONTENT_ID=$(curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content" \
  -F "file=@photo.jpg" \
  -F "rendition=original" | jq -r '.contentId')

# 3. Add thumbnail rendition
curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content/${CONTENT_ID}/renditions" \
  -F "file=@photo_thumb.jpg" \
  -F "renditionType=thumbnail"

# 4. Add medium preview rendition
curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content/${CONTENT_ID}/renditions" \
  -F "file=@photo_preview.jpg" \
  -F "renditionType=preview"

# 5. List all renditions
curl "http://localhost:8080/api/dms/documents/${DOC_ID}/content/${CONTENT_ID}/renditions"
```

### Use Case 2: Document with PDF and Word Versions

```bash
# 1. Create document
DOC_ID=$(curl -X POST "http://localhost:8080/api/dms/documents" \
  -H "Content-Type: application/json" \
  -d '{"title":"Business Report"}' | jq -r '.id')

# 2. Upload original Word document
WORD_ID=$(curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content" \
  -F "file=@report.docx" \
  -F "rendition=original" | jq -r '.contentId')

# 3. Add PDF rendition
curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content/${WORD_ID}/renditions" \
  -F "file=@report.pdf" \
  -F "renditionType=pdf"
```

### Use Case 3: Version a Document with Content

```bash
# 1. Create document with content
DOC_ID=$(curl -X POST "http://localhost:8080/api/dms/documents" \
  -H "Content-Type: application/json" \
  -d '{"title":"Contract v1.0"}' | jq -r '.id')

curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content" \
  -F "file=@contract_v1.pdf" \
  -F "rendition=original"

# 2. Create new version
NEW_VERSION_ID=$(curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/version" \
  -H "Content-Type: application/json" \
  -d '{"note":"Updated terms in section 3"}' | jq -r '.id')

# 3. Upload new content to new version
curl -X POST "http://localhost:8080/api/dms/documents/${NEW_VERSION_ID}/content" \
  -F "file=@contract_v1.1.pdf" \
  -F "rendition=original"
```

### Use Case 4: Video with Thumbnail and Preview

```bash
# 1. Create video document
DOC_ID=$(curl -X POST "http://localhost:8080/api/dms/documents" \
  -H "Content-Type: application/json" \
  -d '{"title":"Training Video"}' | jq -r '.id')

# 2. Upload original video
VIDEO_ID=$(curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content" \
  -F "file=@training.mp4" \
  -F "rendition=original" | jq -r '.contentId')

# 3. Add video thumbnail
curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content/${VIDEO_ID}/renditions" \
  -F "file=@video_thumb.jpg" \
  -F "renditionType=thumbnail"

# 4. Add low-res preview video
curl -X POST "http://localhost:8080/api/dms/documents/${DOC_ID}/content/${VIDEO_ID}/renditions" \
  -F "file=@training_preview.mp4" \
  -F "renditionType=preview"
```

## Rendition Hierarchy

Content objects can form a parent-child hierarchy:

```
Document
├── Content (original.jpg) [storeName="original"]
    ├── Rendition (thumbnail.jpg) [storeName="thumbnail", parentRendition=original]
    ├── Rendition (preview.jpg) [storeName="preview", parentRendition=original]
    └── Rendition (large.jpg) [storeName="large", parentRendition=original]
```

### Key Points:
- **Primary Content**: Uploaded directly to document (no parentRendition)
- **Secondary Renditions**: Created from existing content (has parentRendition set)
- **renditionCount**: Shows how many child renditions exist
- **storeName**: Identifies the rendition type

## Common Rendition Types

| Type | Description | Typical Use |
|------|-------------|-------------|
| `original` | Original uploaded file | Master copy |
| `thumbnail` | Small preview image | Gallery views, listings |
| `preview` | Medium-sized preview | Quick preview before downloading |
| `pdf` | PDF conversion | Standardized viewing format |
| `large` | High-res version | Full-screen viewing |
| `mobile` | Mobile-optimized | Mobile apps |
| `web` | Web-optimized | Web display |
| `print` | Print-quality | Physical printing |

## Version Management

### Version Workflow

1. **Create Document**: Original version (1.0)
2. **Add Content**: Upload files to version 1.0
3. **Create Version**: Generate version 1.1 (createVersion)
4. **Add Updated Content**: Upload new files to version 1.1
5. **Repeat**: Continue versioning as needed

### Version Hierarchy

```
Document (Canonical)
├── Version 1.0 (id=1)
│   ├── Content: report_v1.pdf
│   └── Content: thumbnail.jpg
├── Version 1.1 (id=2, parentVersion=1)
│   ├── Content: report_v1.1.pdf
│   └── Content: thumbnail_updated.jpg
└── Version 2.0 (id=3, parentVersion=2)
    └── Content: report_v2.pdf
```

## React UI Integration

The React DMS UI already supports these operations:

```typescript
// Upload content
await dmsApi.uploadContent(documentId, file, "original");

// Create version
const newVersion = await dmsApi.createVersion(documentId, "Updated content");

// Download content
await dmsApi.downloadContent(documentId, contentId);
```

## Architecture

### Content Storage Flow

```
1. MultipartFile Upload
    ↓
2. Determine ContentType (via filename)
    ↓
3. Create Content object
    ↓
4. Set storeName (rendition type)
    ↓
5. setContent(filename, inputStream, contentType)
    ↓
6. Add to Document.contents
    ↓
7. Persist via DMSSession
```

### Rendition Linking

```
Source Content (id=42)
    ↓ setParentRendition()
Child Rendition (id=43)
    ↓ getRenditions()
Grandchild Rendition (id=44)
```

## Best Practices

### 1. Rendition Naming
Use consistent, descriptive rendition types:
- `original` - Always the source file
- `thumbnail` - Small preview (e.g., 150x150)
- `preview` - Medium preview (e.g., 800x600)
- `pdf` - PDF conversion
- `[format]_[size]` - e.g., "jpeg_large", "mp4_mobile"

### 2. Version Content Strategy
- Upload original content to v1.0
- Create new version before significant changes
- Each version can have its own set of content and renditions
- Use meaningful version notes

### 3. Rendition Generation
- Generate renditions asynchronously when possible
- Create thumbnails immediately for UI responsiveness
- Generate larger renditions in background
- Store rendition metadata (dimensions, duration, etc.)

### 4. Download Optimization
- Use `/content/download` for default/first content
- Use `/content/{id}/download` for specific renditions
- Set proper Content-Disposition headers (already handled)
- Consider caching strategies for frequently accessed renditions

## Error Handling

All endpoints return appropriate HTTP status codes:

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created (for new versions/renditions) |
| 404 | Document or content not found |
| 500 | Server error |
| 503 | DMS not available |

## Performance Considerations

- **Streaming**: Content is streamed for efficient memory usage
- **Lazy Loading**: Renditions loaded only when requested
- **Batch Operations**: Upload multiple renditions in sequence
- **Content Size**: Tracked automatically via Content.contentSize

## Next Steps

1. ✅ Backend endpoints implemented
2. ✅ Versioning support added
3. ✅ Rendition hierarchy supported
4. 🔄 Test with React UI
5. 🔄 Add rendition management UI (optional)
6. 🔄 Implement async rendition generation (optional)

The DMS now has full enterprise-grade content and versioning capabilities!
