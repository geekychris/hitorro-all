#!/bin/bash
# Quick fix script for Hitorro Transformer

echo "========================================="
echo "Hitorro Transformer - Quick Fix Script"
echo "========================================="
echo ""

# Check OS
OS="$(uname -s)"
echo "Detected OS: $OS"
echo ""

# Step 1: Install tools
echo "Step 1: Installing transformation tools..."
echo ""

if [[ "$OS" == "Darwin" ]]; then
    # macOS
    echo "Installing on macOS using Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    brew install poppler libreoffice imagemagick
    
elif [[ "$OS" == "Linux" ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
        echo "Installing on Ubuntu/Debian..."
        sudo apt-get update
        sudo apt-get install -y poppler-utils libreoffice imagemagick
    elif command -v dnf &> /dev/null; then
        echo "Installing on Fedora/RHEL..."
        sudo dnf install -y poppler-utils libreoffice ImageMagick
    elif command -v yum &> /dev/null; then
        echo "Installing on CentOS/RHEL..."
        sudo yum install -y poppler-utils libreoffice ImageMagick
    else
        echo "❌ Unsupported Linux distribution"
        exit 1
    fi
else
    echo "❌ Unsupported operating system: $OS"
    exit 1
fi

echo ""
echo "✅ Tools installed!"
echo ""

# Step 2: Verify installation
echo "Step 2: Verifying installation..."
echo ""

PDFTOPPM=$(which pdftoppm 2>/dev/null || echo "not found")
SOFFICE=$(which soffice 2>/dev/null || echo "not found")
CONVERT=$(which convert 2>/dev/null || echo "not found")

echo "  pdftoppm: $PDFTOPPM"
echo "  soffice:  $SOFFICE"
echo "  convert:  $CONVERT"
echo ""

if [[ "$PDFTOPPM" == "not found" ]] || [[ "$SOFFICE" == "not found" ]] || [[ "$CONVERT" == "not found" ]]; then
    echo "⚠️  Some tools were not found. Transformations may be limited."
    echo ""
else
    echo "✅ All tools verified!"
    echo ""
fi

# Step 3: Instructions for restart
echo "Step 3: Restart the backend"
echo ""
echo "To complete the setup:"
echo ""
echo "1. STOP the Spring Boot application (Ctrl+C or stop in IDE)"
echo ""
echo "2. RESTART with:"
echo "   cd /Users/chris/hitorro/hitorro-example-springboot"
echo "   ./mvnw spring-boot:run"
echo ""
echo "3. LOOK FOR these lines in the logs:"
echo "   ✓ Registered transformer method: pdf_to_image"
echo "   ✓ Registered transformer method: libreoffice_convert"
echo "   ✓ Registered transformer method: imagemagick_convert"
echo ""
echo "4. TEST in browser:"
echo "   http://localhost:3000"
echo "   → Document Management"
echo "   → Select a PDF"
echo "   → Click 'Transform' button"
echo "   → You should see 3 transformation options!"
echo ""
echo "========================================="
echo "Setup complete! Now restart the backend."
echo "========================================="
