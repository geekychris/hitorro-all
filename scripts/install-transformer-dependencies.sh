#!/bin/bash
# Hitorro Transformer Dependencies Installation Script
# Installs all required tools for content transformation
# Continues even if individual tools fail to install


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/transformer-install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Safe install - continues even if installation fails
safe_install() {
    local cmd="$1"
    local package="$2"
    local install_command="$3"
    
    if ! command_exists "$cmd"; then
        log "Installing $package..."
        if eval "$install_command" >> "$LOG_FILE" 2>&1; then
            log_success "$package installed"
            return 0
        else
            log_error "Failed to install $package (continuing anyway)"
            return 1
        fi
    else
        log_success "$package already installed"
        return 0
    fi
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        else
            echo "unknown-linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Install on Ubuntu/Debian
install_ubuntu() {
    log "Installing dependencies on Ubuntu/Debian..."
    
    log "Updating package lists..."
    sudo apt-get update >> "$LOG_FILE" 2>&1 || log_warning "apt-get update failed"
    
    # Existing tools
    safe_install pdftoppm "poppler-utils" "sudo apt-get install -y poppler-utils"
    safe_install soffice "LibreOffice" "sudo apt-get install -y libreoffice libreoffice-writer libreoffice-calc libreoffice-impress"
    safe_install convert "ImageMagick" "sudo apt-get install -y imagemagick"
    
    # NEW: Tier 1 transformers
    safe_install pdftotext "poppler-utils (pdftotext)" "sudo apt-get install -y poppler-utils"
    safe_install gs "Ghostscript" "sudo apt-get install -y ghostscript"
    safe_install tesseract "Tesseract OCR" "sudo apt-get install -y tesseract-ocr tesseract-ocr-eng"
    safe_install ffmpeg "FFmpeg" "sudo apt-get install -y ffmpeg"
    
    # NEW: Tier 2 transformers
    safe_install html2text "html2text" "sudo apt-get install -y html2text"
    safe_install lynx "Lynx (fallback for HTML)" "sudo apt-get install -y lynx"
    safe_install pandoc "Pandoc" "sudo apt-get install -y pandoc"
}

# Install on CentOS/RHEL/Fedora
install_rhel() {
    log "Installing dependencies on RHEL/CentOS/Fedora..."
    
    # Detect package manager
    if command_exists dnf; then
        PKG_MGR="sudo dnf install -y"
    else
        PKG_MGR="sudo yum install -y"
    fi
    
    # Existing tools
    safe_install pdftoppm "poppler-utils" "$PKG_MGR poppler-utils"
    safe_install soffice "LibreOffice" "$PKG_MGR libreoffice"
    safe_install convert "ImageMagick" "$PKG_MGR ImageMagick"
    
    # NEW: Tier 1 transformers
    safe_install pdftotext "poppler-utils (pdftotext)" "$PKG_MGR poppler-utils"
    safe_install gs "Ghostscript" "$PKG_MGR ghostscript"
    safe_install tesseract "Tesseract OCR" "$PKG_MGR tesseract tesseract-langpack-eng"
    safe_install ffmpeg "FFmpeg" "$PKG_MGR ffmpeg"
    
    # NEW: Tier 2 transformers
    safe_install html2text "html2text" "$PKG_MGR python3-html2text"
    safe_install lynx "Lynx (fallback for HTML)" "$PKG_MGR lynx"
    safe_install pandoc "Pandoc" "$PKG_MGR pandoc"
}

# Install on macOS
install_macos() {
    log "Installing dependencies on macOS..."
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        log_error "Homebrew is not installed. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    
    # Existing tools
    safe_install pdftoppm "poppler" "brew install poppler"
    safe_install soffice "LibreOffice" "brew install --cask libreoffice"
    safe_install convert "ImageMagick" "brew install imagemagick"
    
    # NEW: Tier 1 transformers
    safe_install pdftotext "poppler (pdftotext)" "brew install poppler"
    safe_install gs "Ghostscript" "brew install ghostscript"
    safe_install tesseract "Tesseract OCR" "brew install tesseract tesseract-lang"
    safe_install ffmpeg "FFmpeg" "brew install ffmpeg"
    
    # NEW: Tier 2 transformers
    safe_install html2text "html2text" "brew install html2text"
    safe_install lynx "Lynx (fallback for HTML)" "brew install lynx"
    safe_install pandoc "Pandoc" "brew install pandoc"
}

# Verify installations
verify_installations() {
    log ""
    log "Verifying installations..."
    
    local all_ok=true
    local installed_count=0
    local total_count=10
    
    # Check pdftoppm (existing)
    if command_exists pdftoppm; then
        VERSION=$(pdftoppm -v 2>&1 | head -n1 || echo "unknown version")
        log_success "pdftoppm: $VERSION"
        ((installed_count++))
    else
        log_error "pdftoppm not found"
        all_ok=false
    fi
    
    # Check soffice (existing)
    if command_exists soffice; then
        VERSION=$(soffice --version 2>&1 | head -n1 || echo "unknown version")
        log_success "LibreOffice: $VERSION"
        ((installed_count++))
    else
        log_error "soffice (LibreOffice) not found"
        all_ok=false
    fi
    
    # Check convert (existing)
    if command_exists convert; then
        VERSION=$(convert -version 2>&1 | head -n1 || echo "unknown version")
        log_success "ImageMagick: $VERSION"
        ((installed_count++))
    else
        log_error "convert (ImageMagick) not found"
        all_ok=false
    fi
    
    # Check pdftotext (NEW)
    if command_exists pdftotext; then
        VERSION=$(pdftotext -v 2>&1 | head -n1 || echo "unknown version")
        log_success "pdftotext: $VERSION"
        ((installed_count++))
    else
        log_warning "pdftotext not found (PDF text extraction unavailable)"
    fi
    
    # Check ghostscript (NEW)
    if command_exists gs; then
        VERSION=$(gs --version 2>&1 | head -n1 || echo "unknown version")
        log_success "Ghostscript: $VERSION"
        ((installed_count++))
    else
        log_warning "ghostscript not found (PS to PDF and PDF compression unavailable)"
    fi
    
    # Check tesseract (NEW)
    if command_exists tesseract; then
        VERSION=$(tesseract --version 2>&1 | head -n1 || echo "unknown version")
        log_success "Tesseract OCR: $VERSION"
        ((installed_count++))
    else
        log_warning "tesseract not found (OCR unavailable)"
    fi
    
    # Check ffmpeg (NEW)
    if command_exists ffmpeg; then
        VERSION=$(ffmpeg -version 2>&1 | head -n1 || echo "unknown version")
        log_success "FFmpeg: $VERSION"
        ((installed_count++))
    else
        log_warning "ffmpeg not found (video thumbnails unavailable)"
    fi
    
    # Check html2text (NEW)
    if command_exists html2text; then
        VERSION=$(html2text --version 2>&1 | head -n1 || echo "unknown version")
        log_success "html2text: $VERSION"
        ((installed_count++))
    else
        log_warning "html2text not found (will use lynx as fallback)"
    fi
    
    # Check lynx (NEW - fallback)
    if command_exists lynx; then
        VERSION=$(lynx -version 2>&1 | head -n1 || echo "unknown version")
        log_success "Lynx: $VERSION"
        ((installed_count++))
    else
        log_warning "lynx not found (HTML to text conversion may be unavailable)"
    fi
    
    # Check pandoc (NEW)
    if command_exists pandoc; then
        VERSION=$(pandoc --version 2>&1 | head -n1 || echo "unknown version")
        log_success "Pandoc: $VERSION"
        ((installed_count++))
    else
        log_warning "pandoc not found (Markdown to HTML unavailable)"
    fi
    
    log ""
    log "Installed: $installed_count/$total_count tools"
    
    if [ "$all_ok" = true ]; then
        log_success "All core dependencies are installed and working!"
        return 0
    else
        log_error "Some core dependencies are missing. Please check the errors above."
        return 1
    fi
}

# Main installation flow
main() {
    log "========================================"
    log "Hitorro Transformer Dependencies Installer"
    log "========================================"
    log ""
    
    OS=$(detect_os)
    log "Detected OS: $OS"
    log ""
    
    case "$OS" in
        ubuntu|debian)
            install_ubuntu
            ;;
        centos|rhel|fedora)
            install_rhel
            ;;
        macos)
            install_macos
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            log_error "Please install dependencies manually:"
            log_error "  - poppler-utils (pdftoppm)"
            log_error "  - LibreOffice (soffice)"
            log_error "  - ImageMagick (convert)"
            exit 1
            ;;
    esac
    
    log ""
    verify_installations
    
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log ""
        log_success "Installation complete!"
        log ""
        log "Next steps:"
        log "  1. Configure paths in your application.properties (if needed)"
        log "  2. Restart your Hitorro application"
        log "  3. Run tests: ./test-transformer-setup.sh"
    fi
    
    exit $exit_code
}

# Run main
main "$@"
