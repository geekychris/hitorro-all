#!/bin/bash
# Setup script to make soffice accessible in PATH

echo "========================================="
echo "Setting up LibreOffice soffice in PATH"
echo "========================================="
echo ""

# Check if LibreOffice is installed
if [ ! -f "/Applications/LibreOffice.app/Contents/MacOS/soffice" ]; then
    echo "❌ LibreOffice not found at /Applications/LibreOffice.app"
    echo "   Please install LibreOffice first"
    exit 1
fi

echo "✅ LibreOffice found: $(cd /Applications/LibreOffice.app/Contents/MacOS && ./soffice --version)"
echo ""

# Create symlink (requires sudo)
echo "Creating symlink to make 'soffice' accessible..."
echo "You will be prompted for your password:"
echo ""

sudo ln -sf /Applications/LibreOffice.app/Contents/MacOS/soffice /usr/local/bin/soffice

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Symlink created successfully!"
    echo ""
    echo "Testing 'soffice' command:"
    which soffice
    soffice --version
    echo ""
    echo "========================================="
    echo "Setup complete!"
    echo "========================================="
    echo ""
    echo "Now restart your backend:"
    echo "  1. Stop the Spring Boot app (Ctrl+C)"
    echo "  2. Run: cd /Users/chris/hitorro/hitorro-example-springboot"
    echo "  3. Run: ./mvnw spring-boot:run"
    echo ""
    echo "Then test transformations at: http://localhost:3000"
else
    echo ""
    echo "❌ Failed to create symlink"
    echo ""
    echo "Alternative: Add LibreOffice to your PATH manually"
    echo ""
    echo "Add this to your ~/.zshrc or ~/.bash_profile:"
    echo "  export PATH=\"/Applications/LibreOffice.app/Contents/MacOS:\$PATH\""
    echo ""
    echo "Then run: source ~/.zshrc"
fi
