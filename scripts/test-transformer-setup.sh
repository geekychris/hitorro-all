#!/bin/bash
# Test script to verify transformer setup

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "========================================"
echo "Hitorro Transformer Setup Test"
echo "========================================"
echo ""

# Test 1: Check pdftoppm
echo -n "Testing pdftoppm (PDF to Image)... "
if command -v pdftoppm >/dev/null 2>&1; then
    # Create a minimal PDF
    cat > "$TEMP_DIR/test.pdf" << 'EOF'
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]>>endobj
xref
0 4
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
trailer<</Size 4/Root 1 0 R>>
startxref
195
%%EOF
EOF
    
    if pdftoppm -jpeg -f 1 -l 1 -singlefile "$TEMP_DIR/test.pdf" "$TEMP_DIR/output" 2>/dev/null; then
        if [ -f "$TEMP_DIR/output.jpg" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${RED}✗ FAIL (output not created)${NC}"
        fi
    else
        echo -e "${RED}✗ FAIL (conversion failed)${NC}"
    fi
else
    echo -e "${RED}✗ NOT INSTALLED${NC}"
fi

# Test 2: Check LibreOffice
echo -n "Testing LibreOffice (Document to PDF)... "
if command -v soffice >/dev/null 2>&1; then
    # Create a simple text file
    echo "Test Document" > "$TEMP_DIR/test.txt"
    
    if timeout 30 soffice --headless --convert-to pdf --outdir "$TEMP_DIR" "$TEMP_DIR/test.txt" >/dev/null 2>&1; then
        if [ -f "$TEMP_DIR/test.pdf" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${YELLOW}⚠ PARTIAL (command succeeded but output not found)${NC}"
        fi
    else
        echo -e "${RED}✗ FAIL (conversion failed or timeout)${NC}"
    fi
else
    echo -e "${RED}✗ NOT INSTALLED${NC}"
fi

# Test 3: Check ImageMagick
echo -n "Testing ImageMagick (Image Conversion)... "
if command -v convert >/dev/null 2>&1; then
    # Create a simple image
    convert -size 100x100 xc:blue "$TEMP_DIR/test.png" 2>/dev/null || true
    
    if [ -f "$TEMP_DIR/test.png" ]; then
        if convert "$TEMP_DIR/test.png" "$TEMP_DIR/test.jpg" 2>/dev/null; then
            if [ -f "$TEMP_DIR/test.jpg" ]; then
                echo -e "${GREEN}✓ PASS${NC}"
            else
                echo -e "${RED}✗ FAIL (output not created)${NC}"
            fi
        else
            echo -e "${RED}✗ FAIL (conversion failed)${NC}"
        fi
    else
        echo -e "${RED}✗ FAIL (could not create test image)${NC}"
    fi
else
    echo -e "${RED}✗ NOT INSTALLED${NC}"
fi

echo ""
echo "========================================"
echo "Version Information:"
echo "========================================"

if command -v pdftoppm >/dev/null 2>&1; then
    echo "pdftoppm: $(pdftoppm -v 2>&1 | head -n1)"
fi

if command -v soffice >/dev/null 2>&1; then
    echo "LibreOffice: $(soffice --version 2>&1 | head -n1)"
fi

if command -v convert >/dev/null 2>&1; then
    echo "ImageMagick: $(convert -version 2>&1 | head -n1)"
fi

echo ""
echo "Test complete!"
