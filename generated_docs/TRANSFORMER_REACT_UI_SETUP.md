# Transformer React UI - Setup Guide

## Overview

The Content Transformer UI is integrated into the Hitorro React application as a dedicated tab.

## Quick Start

### 1. Start the Backend

```bash
cd hitorro-example-springboot
./mvnw spring-boot:run
```

Backend will run on `http://localhost:8080`

### 2. Start the React Frontend

```bash
cd hitorro-example-springboot/react-app
npm install  # First time only
npm run dev
```

Frontend will run on `http://localhost:3000`

### 3. Access the Transformer UI

1. Open browser to `http://localhost:3000`
2. Click on the **"Content Transformer"** tab
3. Use the 4-step wizard to queue transformations

## Features

### React Components

**File**: `hitorro-example-springboot/react-app/src/pages/TransformerPage.tsx`

- **Modern React**: Uses hooks (useState, useEffect)
- **TypeScript**: Fully typed for safety
- **Axios Integration**: Uses existing API service
- **Responsive Design**: Works on all screen sizes
- **Real-time Validation**: Button states based on selections
- **Error Handling**: Clear error messages
- **Success Feedback**: Visual confirmation of actions

### Integration

The Transformer tab is integrated alongside existing features:
- Document Management
- Filesystem Crawler
- Type System
- Commands
- REST API Explorer
- Services Explorer

### API Endpoints Used

All endpoints are already configured in the backend:

```typescript
GET  /api/documents/recent?limit=20
GET  /api/documents/search?q={query}
GET  /api/documents/{guid}/content
GET  /api/transformer/content/{guid}/available-transformations
POST /api/transformer/queue
```

## Development

### File Structure

```
hitorro-example-springboot/react-app/
├── src/
│   ├── pages/
│   │   └── TransformerPage.tsx        # New transformer UI
│   ├── services/
│   │   └── api.ts                     # API client (existing)
│   ├── App.tsx                        # Updated with transformer tab
│   └── ...
├── package.json
└── vite.config.ts
```

### Dependencies

All required dependencies are already installed:
- `react` & `react-dom`
- `axios` (for API calls)
- `@tanstack/react-query` (for data fetching)
- `react-router-dom` (for routing)

### Running in Development

The React app uses Vite for fast development:

```bash
cd hitorro-example-springboot/react-app
npm run dev
```

Features:
- **Hot Module Replacement** - Changes appear instantly
- **Fast Refresh** - React state preserved on edits
- **TypeScript** - Type checking in real-time

### Building for Production

```bash
cd hitorro-example-springboot/react-app
npm run build
```

This creates optimized files in `dist/` directory.

To serve the built files:

```bash
npm run preview
```

## Customization

### Styling

The component uses inline styles for simplicity. To customize:

1. **Colors**: Change color values in the component
2. **Layout**: Modify flexbox/grid properties
3. **Spacing**: Adjust padding/margin values

Example:
```typescript
// Change primary color from purple to blue
style={{ background: '#667eea' }} // Change to '#007bff'
```

### Adding Features

To add new features to the Transformer page:

1. Add state variables with `useState`
2. Add new UI elements in the JSX
3. Add API calls with `axios`
4. Update TypeScript interfaces as needed

Example - Add progress tracking:
```typescript
const [progress, setProgress] = useState<number>(0);

// In your component
{progress > 0 && (
  <div style={{ width: '100%', background: '#e0e0e0' }}>
    <div style={{ width: `${progress}%`, background: '#667eea', height: '4px' }} />
  </div>
)}
```

## Troubleshooting

### Issue: React app won't start

**Solutions:**
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Check Node version (requires 16+)
node --version
```

### Issue: API calls failing

**Solutions:**
- Verify backend is running on `http://localhost:8080`
- Check browser console for CORS errors
- Verify API endpoints with curl

### Issue: "Cannot find module"

**Solutions:**
```bash
# Reinstall dependencies
npm install

# Check TypeScript compilation
npm run build
```

### Issue: Transformer tab not showing

**Solutions:**
- Verify `TransformerPage.tsx` exists
- Check `App.tsx` imports
- Clear browser cache
- Check browser console for errors

## Testing

### Manual Testing

1. Start backend and frontend
2. Navigate to Transformer tab
3. Test each step:
   - Search/browse documents
   - Select document
   - View content list
   - Select content
   - View transformations
   - Queue job

### API Testing

Test endpoints independently:

```bash
# Recent documents
curl http://localhost:8080/api/documents/recent

# Search
curl http://localhost:8080/api/documents/search?q=test

# Content
curl http://localhost:8080/api/documents/{guid}/content
```

## Production Deployment

### Option 1: Serve from Spring Boot

1. Build React app:
```bash
cd hitorro-example-springboot/react-app
npm run build
```

2. Copy `dist/` contents to Spring Boot `src/main/resources/static/`

3. Access at `http://localhost:8080/`

### Option 2: Separate Deployment

1. Deploy React app to static hosting (Netlify, Vercel, etc.)
2. Configure CORS on Spring Boot backend
3. Update API base URL in React app

## Next Steps

- [ ] Add real-time job progress updates
- [ ] Add transformation history
- [ ] Add batch transformation support
- [ ] Add advanced search filters
- [ ] Add preview of renditions
- [ ] Add drag-and-drop file upload

## Resources

- **React Documentation**: https://react.dev
- **Vite Documentation**: https://vitejs.dev
- **Axios Documentation**: https://axios-http.com
- **TypeScript**: https://www.typescriptlang.org

---

**Ready to transform!** 🚀 Open `http://localhost:3000` and click "Content Transformer"
