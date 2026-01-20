# DMS Versioning and Upload Fixes - Complete ✅

## Summary

Fixed two critical issues:
1. **Upload Content 500 Error** - Content persistence issue
2. **Version Labels stuck at 1.0** - Now supports proper major/minor versioning

## Issue 1: Upload Content 500 Error ✅

### Problem
Uploading files to documents resulted in "AxiosError: Request failed with status code 500"

### Root Cause
Content object wasn't being persisted before setting binary data, and the Store wasn't properly initialized.

### Solution
Updated `uploadContent()` method in `DocumentManagementController.java`:

**Before (broken):**
```java
Content content = new Content();
content.setStoreName(storeName);
content.setContent(fileName, inputStream, contentType);
document.getContents().add(content);
session.saveOrUpdate(document);
```

**After (fixed):**
```java
Content content = new Content();

// Get default store - Content needs valid store
Store defaultStore = StoreUtil.getDefaultStore();
if (defaultStore != null) {
    content.setStoreName(defaultStore.getSoftGuid());
}

// Persist content FIRST before setting binary data
session.persist(content);

// Then set binary content
content.setContent(fileName, inputStream, contentType);

// Add to document and save both
document.getContents().add(content);
session.saveOrUpdate(document);
session.saveOrUpdate(content);
```

**Key changes:**
1. Use `StoreUtil.getDefaultStore()` for proper store initialization
2. `session.persist(content)` BEFORE `setContent()` 
3. Save both document and content explicitly

## Issue 2: Version Labels Stuck at 1.0 ✅

### Problem
Creating new versions always showed "1.0" for version label instead of incrementing (e.g., 1.0 → 2.0 or 1.0 → 1.1)

### Root Cause
Custom versioning code wasn't using Hitorro's built-in versioning infrastructure (`createMajorVersion()` and `createMinorVersion()` methods from `VersionableObject`).

### Solution

#### Backend: Use Hitorro's Versioning API

Updated `checkoutDocument()` endpoint to use proper Hitorro methods:

**Before (broken):**
```java
Document newVersion = new Document();
newVersion.setTitle(document.getTitle() + " (v" + timestamp + ")");
// ... manual copying, no version label update
```

**After (fixed):**
```java
// Use Hitorro's built-in versioning
Document newVersion;
if ("minor".equalsIgnoreCase(versionType)) {
    newVersion = (Document) document.createMinorVersion();
    // 1.0 → 1.1, 1.1 → 1.2, etc.
} else {
    newVersion = (Document) document.createMajorVersion();
    // 1.0 → 2.0, 2.0 → 3.0, etc.
}

session.persist(newVersion);
session.commit();
```

**How it works:**
- `createMajorVersion()` uses `VersioningUtil.getMajorVersion()` to increment major number
- `createMinorVersion()` uses `VersioningUtil.getMinorVersion()` to increment minor number
- Automatically handles version label, canonical GUID, parent version relationships

#### Frontend: Major/Minor Version Buttons

Replaced single "Create Version" button with TWO buttons:

**Major Version Button** (Yellow, GitBranch icon)
- Creates new major version: 1.0 → 2.0, 2.0 → 3.0, etc.
- Confirmation: "Create a new MAJOR version? (e.g., 1.0 → 2.0)"
- Shows before/after version labels on success

**Minor Version Button** (Blue, GitBranch icon)  
- Creates new minor version: 1.0 → 1.1, 1.1 → 1.2, 2.0 → 2.1, etc.
- Confirmation: "Create a new MINOR version? (e.g., 1.0 → 1.1)"
- Shows before/after version labels on success

#### API Service Update

```typescript
// services/api.ts
checkoutDocument: (id: number, versionType: 'major' | 'minor' = 'major') =>
  api.put<Document>(`/dms/documents/${id}/checkout?versionType=${versionType}`)
```

## Testing

### Test Upload Content
```bash
# Via UI
1. Go to http://localhost:3000 → Document Management
2. Click any document
3. Click "Upload Content" button (blue, Upload icon)
4. Select file → See size preview
5. Click "Upload" → SUCCESS! ✅

# Via API
curl -X POST http://localhost:8080/api/dms/documents/1106/content \
  -F "file=@test.txt"
```

### Test Major Version
```bash
# Via UI
1. Click document with version "1.0"
2. Click "Major Version" button (yellow)
3. Confirm
4. See: "Old: 1.0, New: 2.0, ID: 1234" ✅

# Via API
curl -X PUT "http://localhost:8080/api/dms/documents/1106/checkout?versionType=major"
```

### Test Minor Version
```bash
# Via UI
1. Click document with version "1.0"
2. Click "Minor Version" button (blue)
3. Confirm
4. See: "Old: 1.0, New: 1.1, ID: 1235" ✅

# Via API
curl -X PUT "http://localhost:8080/api/dms/documents/1106/checkout?versionType=minor"
```

## Version Label Examples

Starting from version **1.0**:

| Action | Old Version | New Version | Notes |
|--------|-------------|-------------|-------|
| Major | 1.0 | 2.0 | Breaking changes |
| Minor | 1.0 | 1.1 | Incremental update |
| Minor | 1.1 | 1.2 | Another update |
| Major | 1.2 | 2.0 | Next major release |
| Minor | 2.0 | 2.1 | Update to v2 |
| Major | 2.1 | 3.0 | Next major |

## Technical Details

### Hitorro Versioning Infrastructure

**VersionableObject.java** provides:
- `createMajorVersion()` - Increments major number, resets minor to 0
- `createMinorVersion()` - Increments minor number
- `createBranchVersion()` - Creates branch version
- Uses `VersioningUtil` for version label calculations

**VersioningUtil.java** provides:
- `getMajorVersion(String currentVersion)` - "1.0" → "2.0"
- `getMinorVersion(String currentVersion)` - "1.0" → "1.1"
- `getBranch(String currentVersion)` - Creates branch label

### Document Relationships

When creating versions:
- **canonicalGuid** - Same for all versions of a document
- **parentVersion** - Links to previous version
- **versionLabel** - Human-readable version (e.g., "1.0", "2.3")

## What's Working Now

✅ **Upload Content** - Files attach successfully to documents  
✅ **Major Versions** - 1.0 → 2.0 → 3.0, etc.  
✅ **Minor Versions** - 1.0 → 1.1 → 1.2, etc.  
✅ **Version Display** - Shows old/new version labels on success  
✅ **Proper Store Initialization** - Content uses default store  
✅ **Content Persistence** - Binary data saved correctly  

## Future Enhancements

- Add branch versions (for experimental changes)
- Version comparison UI (diff between versions)
- Version tree visualization
- Revert to previous version
- Version labels shown in document list
- Filter documents by version

## Status

**Backend**: Running at http://localhost:8080 ✅  
**Frontend**: Running at http://localhost:3000 ✅

Both upload and versioning are **fully functional with proper Hitorro integration**!
