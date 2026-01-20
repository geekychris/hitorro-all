# Hitorro Transformer - Web UI Guide

The Hitorro Transformer includes a modern, user-friendly web interface for queuing content transformations.

## 🎨 UI Overview

The web interface provides a **4-step wizard** to guide users through the transformation process:

1. **Select Document** - Browse or search for documents
2. **Choose Content** - Pick a content rendition to transform
3. **Select Format** - Choose the target format from available transformations
4. **Confirm** - Review and queue the transformation job

## 🚀 Accessing the UI

### URL
```
http://localhost:3000
```

Then click on the **"Content Transformer"** tab.

### Requirements
- Hitorro Spring Boot backend running (`http://localhost:8080`)
- React frontend running (`npm run dev` in `hitorro-example-springboot/react-app`)
- Transformer service enabled (`hitorro.transformer.enabled=true`)
- At least one document with content in the database

## 📋 Step-by-Step Guide

### Step 1: Select a Document

**Search Options:**
- **Search by Title/GUID**: Enter keywords or a document GUID
- **Load Recent**: View the 20 most recently created documents

**Actions:**
- Click on a document card to select it
- Selected document will be highlighted in blue
- Click "Next: Choose Content" to proceed

### Step 2: Choose Content Rendition

**Content Display:**
- All content renditions for the selected document are shown
- Each content shows:
  - File name
  - MIME type
  - GUID

**Actions:**
- Click on a content item to select it
- Selected content will have a green left border
- Click "Next: Select Format" to proceed

### Step 3: Select Target Format

**Available Transformations:**
- Only transformations available for the selected content type are shown
- Each option displays:
  - Target MIME type
  - Transformation method
  - Availability badge (green = available, red = unavailable)

**Common Transformations:**
- PDF → JPEG (for previews/thumbnails)
- PDF → PNG (high quality images)
- Word/Excel/PowerPoint → PDF
- Image → JPEG/PNG

**Actions:**
- Click on a transformation to select it
- Only available transformations can be selected
- Click "Next: Confirm" to proceed

### Step 4: Confirm and Queue

**Review:**
- Document name
- Source content file and type
- Target format and method

**Options:**
- **Rendition Tag**: Label for the new rendition (default: "converted")
  - Examples: "preview", "thumbnail", "pdf_version", "web_optimized"
- **Target Filename**: Optional custom name for the output file
- **Add as Child**: Check to link the new rendition to the source content

**Actions:**
- Click "Queue Transformation" to submit the job
- Job will be queued for asynchronous processing
- Success message shows Job ID and GUID

## 🎯 Usage Examples

### Example 1: Create PDF Preview Image

**Scenario**: Generate a JPEG thumbnail from a PDF document

1. Search for your PDF document
2. Select the PDF content rendition
3. Choose "image/jpeg" transformation
4. Set tag value to "thumbnail"
5. Queue the transformation

**Result**: New JPEG image created and linked to the PDF

### Example 2: Convert Word to PDF

**Scenario**: Create a PDF version of a Word document

1. Find the document with .docx content
2. Select the Word content
3. Choose "application/pdf" transformation
4. Set tag value to "pdf_version"
5. Queue the transformation

**Result**: PDF version created and added to the document

### Example 3: Resize Image

**Scenario**: Create a web-optimized version of a large image

1. Select document with image content
2. Choose the image content
3. Select image transformation (e.g., PNG → JPEG)
4. Set tag value to "web_optimized"
5. Queue the transformation

**Result**: Optimized image created

## 🔌 REST API Endpoints Used by UI

The UI communicates with these endpoints:

### Document Endpoints

```bash
# Get recent documents
GET /api/documents/recent?limit=20

# Search documents
GET /api/documents/search?q=query

# Get document content
GET /api/documents/{documentGuid}/content

# Get content details
GET /api/documents/content/{contentGuid}
```

### Transformer Endpoints

```bash
# Get available transformations
GET /api/transformer/content/{contentGuid}/available-transformations

# Queue transformation
POST /api/transformer/queue
```

## 🎨 UI Features

### Modern Design
- **Gradient Background**: Professional purple gradient
- **Card-based Layout**: Clean, organized sections
- **Responsive**: Works on desktop, tablet, and mobile
- **Step Indicator**: Visual progress through wizard
- **Color-coded**: Green for success, red for errors, blue for info

### User Experience
- **Visual Feedback**: Immediate highlighting of selections
- **Validation**: Disabled buttons until selections are made
- **Error Handling**: Clear error messages
- **Success Confirmation**: Detailed job information on completion

### Accessibility
- **Clear Labels**: All form fields labeled
- **Keyboard Navigation**: Tab through elements
- **Color Contrast**: Meets WCAG standards
- **Responsive Buttons**: Large, easy-to-click targets

## 🛠️ Customization

### Styling

The UI uses inline CSS for easy customization. Key color variables:

```css
Primary Color: #667eea
Secondary Color: #764ba2
Success Color: #28a745
Error Color: #f8d7da
```

To customize, edit `transformer.html` and modify the `<style>` section.

### Configuration

Default values can be changed in the JavaScript:

```javascript
const API_BASE = '/api';  // API endpoint base
const DEFAULT_LIMIT = 20;  // Documents to load
```

### Adding Features

To add new features:

1. Add HTML elements in the appropriate step
2. Add JavaScript functions for new functionality
3. Update API endpoints if needed
4. Test thoroughly

## 📊 Monitoring Transformations

### Job Status

After queuing, the UI displays:
- Job ID (for tracking)
- Job GUID (database reference)
- Status (queued, processing, completed)

### Checking Results

**Via API:**
```bash
# Get document content to see new renditions
GET /api/documents/{documentGuid}/content
```

**Via Database:**
```sql
SELECT * FROM Content WHERE parentRendition_id = ?
```

**Via UI:**
- Reload the UI and select the same document
- New rendition will appear in Step 2

## 🐛 Troubleshooting

### Issue: No Documents Appear

**Causes:**
- Database is empty
- Search query too specific
- Database connection issue

**Solutions:**
- Create test documents
- Try "Load Recent" instead of search
- Check application logs

### Issue: No Transformations Available

**Causes:**
- Transformer tools not installed
- Source MIME type not configured in edges.csv
- TransformerService not initialized

**Solutions:**
- Run `./scripts/test-transformer-setup.sh`
- Check `data/transcoder/edges.csv` for source MIME type
- Review application logs for transformer registration

### Issue: Queue Button Disabled

**Causes:**
- Missing required fields
- JavaScript error
- Invalid selection

**Solutions:**
- Complete all previous steps
- Check browser console for errors
- Refresh page and try again

### Issue: Job Queued but Not Processing

**Causes:**
- Worker threads not running
- Transformer tool failure
- Database issue

**Solutions:**
- Check `TransformerService` logs
- Verify tools with `./scripts/test-transformer-setup.sh`
- Check job queue table in database

## 🔐 Security Considerations

### Access Control

The UI currently has no authentication. For production:

1. Add Spring Security authentication
2. Implement role-based access control
3. Validate user permissions before querying documents

```java
@PreAuthorize("hasRole('USER')")
@GetMapping("/api/documents/recent")
public ResponseEntity<?> getRecentDocuments() {
    // Implementation
}
```

### Input Validation

The API validates:
- Document/content GUIDs exist
- Transformations are available
- MIME types are valid

Additional validation can be added for:
- File size limits
- Maximum concurrent jobs per user
- Rate limiting

## 🎓 Advanced Usage

### Batch Transformations

To queue multiple transformations:

1. Select document
2. Select first content
3. Queue transformation
4. Click "Start New Transformation" (or go back to Step 2)
5. Select next content
6. Repeat

### Custom Parameters

Edit `edges.csv` to customize transformation parameters:

```csv
MimeFrom,MimeTo,Transformer,Method,MethodArgs
application/pdf,image/jpeg,pdf_converter,pdf_to_image,"format=jpeg,dpi=72,quality=70"
```

Lower DPI and quality = faster, smaller files

### Integration with Your UI

To embed in your application:

1. Copy relevant sections from `transformer.html`
2. Style to match your design
3. Use the same API endpoints
4. Add your authentication/authorization

## 📱 Mobile Responsive

The UI is fully responsive:

- **Desktop**: Full 4-column grid for documents
- **Tablet**: 2-column grid
- **Mobile**: Single column, stacked layout

## 🚀 Performance Tips

1. **Limit Results**: Use pagination for large document lists
2. **Cache**: Browser caches static resources
3. **Lazy Load**: Load content only when needed
4. **Batch**: Queue multiple jobs at once

## 📝 Future Enhancements

Potential features to add:

- [ ] Real-time job progress updates (WebSocket)
- [ ] Batch transformation UI
- [ ] Transformation history/audit log
- [ ] Advanced search filters (by content type, date, etc.)
- [ ] Preview renditions before download
- [ ] Drag-and-drop file upload for new content
- [ ] Transformation presets/templates
- [ ] Email notifications on completion

## 🔗 Related Documentation

- [TRANSFORMER_QUICK_START.md](TRANSFORMER_QUICK_START.md) - Setup guide
- [TRANSFORMER_README.md](TRANSFORMER_README.md) - Overview
- [TRANSFORMER_IMPLEMENTATION_GUIDE.md](TRANSFORMER_IMPLEMENTATION_GUIDE.md) - Technical details

---

**Start transforming!** Open `http://localhost:8080/transformer.html` 🎨
