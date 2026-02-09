#!/usr/bin/env bash
set -e

# OpenCode Uninstall Script
# Removes locally installed OpenCode

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
INSTALLED_PATH="$INSTALL_DIR/opencode"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo ""
echo -e "${BOLD}${BLUE}OpenCode Uninstall${NC}"
echo ""

if [ ! -e "$INSTALLED_PATH" ]; then
    print_error "OpenCode is not installed at: $INSTALLED_PATH"
    echo ""
    print_info "If you installed it elsewhere, remove it manually:"
    echo "  which opencode"
    echo "  rm \$(which opencode)"
    exit 1
fi

if [ -L "$INSTALLED_PATH" ]; then
    TARGET=$(readlink "$INSTALLED_PATH")
    echo "Found OpenCode (symlink):"
    echo "  Link:   $INSTALLED_PATH"
    echo "  Target: $TARGET"
elif [ -f "$INSTALLED_PATH" ]; then
    echo "Found OpenCode (file):"
    echo "  Path: $INSTALLED_PATH"
fi

echo ""
read -p "Remove OpenCode? (y/N): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

rm "$INSTALLED_PATH"
print_success "Removed: $INSTALLED_PATH"
echo ""

if command -v opencode &> /dev/null; then
    print_info "Note: 'opencode' command still found in PATH"
    echo "  Path: $(which opencode)"
    echo "  This might be the npm global installation or another copy"
else
    print_success "OpenCode is no longer available globally"
fi

echo ""
print_info "To reinstall from local build:"
echo "  ./install.sh"
echo ""
print_info "To install from npm:"
echo "  npm install -g opencode-ai@1.1.10"
echo ""
