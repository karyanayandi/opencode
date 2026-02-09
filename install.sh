#!/usr/bin/env bash
set -e

# OpenCode Local Installation Script
# This script installs your locally built OpenCode to be available globally

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo -e "${BOLD}${BLUE}"
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header "OpenCode Local Installation"

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture names
case "$ARCH" in
    x86_64)
        ARCH="x64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Map OS names
case "$OS" in
    linux)
        OS="linux"
        BINARY_NAME="opencode"
        ;;
    darwin)
        OS="darwin"
        BINARY_NAME="opencode"
        ;;
    mingw*|msys*|cygwin*)
        OS="windows"
        BINARY_NAME="opencode.exe"
        ;;
    *)
        print_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac

PLATFORM="${OS}-${ARCH}"
print_info "Detected platform: $PLATFORM"
echo ""

# Check if built
DIST_DIR="$SCRIPT_DIR/packages/opencode/dist"
BINARY_DIR="$DIST_DIR/opencode-$PLATFORM/bin"
BINARY_PATH="$BINARY_DIR/$BINARY_NAME"

if [ ! -f "$BINARY_PATH" ]; then
    print_error "Binary not found: $BINARY_PATH"
    echo ""
    print_info "You need to build OpenCode first:"
    echo "  ./build.sh"
    echo ""
    echo "Available builds:"
    ls -1 "$DIST_DIR" 2>/dev/null || echo "  (none - run ./build.sh)"
    exit 1
fi

print_success "Found binary: $BINARY_PATH"
echo ""

# Check install directory
if [ ! -d "$INSTALL_DIR" ]; then
    print_warning "Install directory doesn't exist: $INSTALL_DIR"
    read -p "Create it? (Y/n): " create
    if [[ ! $create =~ ^[Nn]$ ]]; then
        mkdir -p "$INSTALL_DIR"
        print_success "Created $INSTALL_DIR"
    else
        echo "Cancelled."
        exit 1
    fi
fi

# Check if already installed
INSTALLED_PATH="$INSTALL_DIR/opencode"
if [ -L "$INSTALLED_PATH" ]; then
    CURRENT_TARGET=$(readlink "$INSTALLED_PATH")
    print_warning "OpenCode is already installed (symlink)"
    echo "  Current: $CURRENT_TARGET"
    echo "  New:     $BINARY_PATH"
    echo ""
    read -p "Replace it? (y/N): " replace
    if [[ ! $replace =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    rm "$INSTALLED_PATH"
elif [ -f "$INSTALLED_PATH" ]; then
    print_warning "OpenCode is already installed (file)"
    echo "  Path: $INSTALLED_PATH"
    echo ""
    read -p "Replace it? (y/N): " replace
    if [[ ! $replace =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    rm "$INSTALLED_PATH"
fi

# Create symlink
ln -s "$BINARY_PATH" "$INSTALLED_PATH"
print_success "Installed OpenCode to: $INSTALLED_PATH"
echo ""

# Check if in PATH
if echo "$PATH" | grep -q "$INSTALL_DIR"; then
    print_success "$INSTALL_DIR is in your PATH"
else
    print_warning "$INSTALL_DIR is NOT in your PATH"
    echo ""
    echo "To use 'opencode' command globally, add this to your shell config:"
    echo ""
    
    # Detect shell
    CURRENT_SHELL=$(basename "$SHELL" 2>/dev/null || echo "unknown")
    
    if [ "$CURRENT_SHELL" = "fish" ]; then
        echo "  ${BOLD}# For Fish shell:${NC}"
        echo "  fish_add_path -p $INSTALL_DIR"
    elif [ -n "$BASH_VERSION" ]; then
        echo "  ${BOLD}# Add to ~/.bashrc:${NC}"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    elif [ -n "$ZSH_VERSION" ]; then
        echo "  ${BOLD}# Add to ~/.zshrc:${NC}"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    else
        echo "  ${BOLD}# Add to your shell config:${NC}"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
    
    echo ""
    
    read -p "Add to PATH automatically? (y/N): " add_path
    if [[ $add_path =~ ^[Yy]$ ]]; then
        SHELL_CONFIG=""
        SHELL_TYPE="unknown"
        
        # Detect Fish shell
        if [ "$CURRENT_SHELL" = "fish" ]; then
            SHELL_TYPE="fish"
            # Add to Fish path using fish_add_path
            if command -v fish &> /dev/null; then
                fish -c "fish_add_path -p $INSTALL_DIR" 2>/dev/null
                if [ $? -eq 0 ]; then
                    print_success "Added to Fish shell PATH"
                    echo ""
                    print_warning "Restart your Fish shell or run: exec fish"
                else
                    print_error "Failed to add to Fish PATH"
                    echo "Please run manually: fish_add_path -p $INSTALL_DIR"
                fi
            else
                print_error "Fish shell not found"
                echo "Please run manually: fish_add_path -p $INSTALL_DIR"
            fi
        # Detect Bash/Zsh
        else
            if [ -n "$BASH_VERSION" ]; then
                SHELL_CONFIG="$HOME/.bashrc"
                SHELL_TYPE="bash"
            elif [ -n "$ZSH_VERSION" ]; then
                SHELL_CONFIG="$HOME/.zshrc"
                SHELL_TYPE="zsh"
            elif [ -f "$HOME/.bashrc" ]; then
                SHELL_CONFIG="$HOME/.bashrc"
                SHELL_TYPE="bash"
            elif [ -f "$HOME/.zshrc" ]; then
                SHELL_CONFIG="$HOME/.zshrc"
                SHELL_TYPE="zsh"
            fi
            
            if [ -n "$SHELL_CONFIG" ]; then
                # Check if already in config
                if ! grep -q "$INSTALL_DIR" "$SHELL_CONFIG" 2>/dev/null; then
                    echo "" >> "$SHELL_CONFIG"
                    echo "# OpenCode local installation" >> "$SHELL_CONFIG"
                    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
                    print_success "Added to $SHELL_CONFIG"
                    echo ""
                    print_warning "Restart your shell or run: source $SHELL_CONFIG"
                else
                    print_info "$INSTALL_DIR already in $SHELL_CONFIG"
                fi
            else
                print_error "Could not detect shell config file"
                echo "Please add manually to your shell config."
            fi
        fi
    fi
fi

echo ""
print_header "Installation Complete!"

# Test if command works
if command -v opencode &> /dev/null; then
    VERSION=$(opencode --version 2>&1 || echo "unknown")
    print_success "OpenCode is available globally!"
    echo "  Command: opencode"
    echo "  Path:    $(which opencode)"
    echo "  Version: $VERSION"
else
    print_warning "OpenCode command not found yet"
    echo "You may need to:"
    echo "  1. Add $INSTALL_DIR to your PATH (see above)"
    echo "  2. Restart your shell"
    echo "  3. Or use the full path: $INSTALLED_PATH"
fi

echo ""
echo "Usage:"
echo "  ${BOLD}opencode${NC}          - Start OpenCode"
echo "  ${BOLD}opencode --help${NC}   - Show help"
echo "  ${BOLD}opencode --version${NC} - Show version"
echo ""

print_info "To rebuild and reinstall:"
echo "  ./build.sh && ./install.sh"
echo ""

print_info "To uninstall:"
echo "  rm $INSTALLED_PATH"
echo ""
