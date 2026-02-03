#!/bin/bash
# Create test documents for transformer testing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DATA_DIR="${SCRIPT_DIR}/../test-data/transformer"

mkdir -p "$TEST_DATA_DIR"

echo "Creating test documents in $TEST_DATA_DIR..."

# Create a test PDF
cat > "$TEST_DATA_DIR/test-document.pdf" << 'EOF'
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
4 0 obj<</Length 88>>stream
BT
/F1 48 Tf
100 700 Td
(Hitorro Test PDF) Tj
0 -100 Td
/F1 24 Tf
(Content Transformation Demo) Tj
ET
endstream
endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
xref
0 6
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000262 00000 n
0000000398 00000 n
trailer<</Size 6/Root 1 0 R>>
startxref
463
%%EOF
EOF

# Create a test text file (for LibreOffice)
cat > "$TEST_DATA_DIR/test-document.txt" << 'EOF'
Hitorro Content Transformation Test Document
===========================================

This is a test document for the Hitorro transformer framework.

Features:
- PDF to Image conversion
- Office document to PDF conversion
- Image format conversion and resizing

This document can be converted to PDF using LibreOffice transformer.

Test Content:
Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

Transformations Available:
1. Document to PDF
2. PDF to Image (JPEG, PNG, TIFF)
3. Image resizing and format conversion

For more information, see TRANSFORMER_QUICK_START.md
EOF

# Create a simple test image (requires ImageMagick)
if command -v convert >/dev/null 2>&1; then
    convert -size 400x300 \
        -background lightblue \
        -fill darkblue \
        -pointsize 32 \
        -gravity center \
        label:"Hitorro\nTest Image\n\nTransformer Framework" \
        "$TEST_DATA_DIR/test-image.png" 2>/dev/null || {
        echo "Warning: Could not create test image (ImageMagick might not be installed)"
    }
fi

# Create a simple HTML file (for LibreOffice)
cat > "$TEST_DATA_DIR/test-document.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Hitorro Transformer Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #2c3e50; }
        .section { margin: 20px 0; padding: 15px; background: #ecf0f1; }
    </style>
</head>
<body>
    <h1>Hitorro Content Transformation Framework</h1>
    
    <div class="section">
        <h2>Test Document</h2>
        <p>This HTML document can be converted to PDF using the LibreOffice transformer.</p>
    </div>
    
    <div class="section">
        <h2>Supported Features</h2>
        <ul>
            <li>PDF to Image (JPEG, PNG, TIFF)</li>
            <li>Office Documents to PDF (Word, Excel, PowerPoint)</li>
            <li>Image Format Conversion</li>
            <li>Image Resizing and Quality Control</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Quick Start</h2>
        <p>See <code>TRANSFORMER_QUICK_START.md</code> for setup instructions.</p>
    </div>
</body>
</html>
EOF

echo ""
echo "Test documents created:"
ls -lh "$TEST_DATA_DIR"
echo ""
echo "Test Documents Summary:"
echo "  - test-document.pdf   : Simple PDF for testing PDF to image conversion"
echo "  - test-document.txt   : Text file for LibreOffice conversion to PDF"
echo "  - test-document.html  : HTML file for LibreOffice conversion to PDF"
if [ -f "$TEST_DATA_DIR/test-image.png" ]; then
    echo "  - test-image.png      : Test image for format conversion and resizing"
fi
echo ""
echo "Usage Examples:"
echo ""
echo "1. Convert PDF to JPEG:"
echo "   pdftoppm -jpeg -r 150 $TEST_DATA_DIR/test-document.pdf output"
echo ""
echo "2. Convert text to PDF:"
echo "   soffice --headless --convert-to pdf --outdir /tmp $TEST_DATA_DIR/test-document.txt"
echo ""
if [ -f "$TEST_DATA_DIR/test-image.png" ]; then
    echo "3. Resize image:"
    echo "   convert $TEST_DATA_DIR/test-image.png -resize 50% /tmp/resized.png"
    echo ""
fi
