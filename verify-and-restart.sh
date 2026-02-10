#!/usr/bin/env bash
set -e

# OpenCode Billing Fix - Verification & Restart Script

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

print_header "OpenCode Billing Fix - Verification & Restart"

echo "This script will:"
echo "  1. Kill all running OpenCode processes"
echo "  2. Verify the patch is applied"
echo "  3. Start fresh OpenCode session"
echo "  4. Guide you through billing verification"
echo ""

read -p "Continue? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
print_header "Step 1: Killing OpenCode Processes"

PROCESSES=$(ps aux | grep -i "opencode" | grep -v grep | grep -v "$0" | awk '{print $2}')

if [ -z "$PROCESSES" ]; then
    print_info "No OpenCode processes running"
else
    echo "Found OpenCode processes:"
    ps aux | grep -i "opencode" | grep -v grep | grep -v "$0"
    echo ""
    
    for pid in $PROCESSES; do
        kill -9 $pid 2>/dev/null && print_success "Killed process $pid" || print_warning "Could not kill $pid"
    done
fi

sleep 2

echo ""
print_header "Step 2: Verifying Configuration"

# Check patch status
if [ ! -f "packages/opencode/src/plugin/copilot.ts" ]; then
    print_success "Option 1 is applied (copilot.ts removed)"
    OPTION="Option 1"
elif grep -q "Only set x-initiator for subagent requests" "packages/opencode/src/plugin/copilot.ts" 2>/dev/null; then
    print_success "Option 2 is applied (modified copilot.ts)"
    OPTION="Option 2"
else
    print_error "No patch is applied!"
    echo ""
    echo "Run one of these first:"
    echo "  ./run.sh apply1  # For Option 1 (recommended)"
    echo "  ./run.sh apply2  # For Option 2 (keep features)"
    echo ""
    exit 1
fi

# Check binary exists
BINARY="packages/opencode/dist/opencode-linux-x64/bin/opencode"
if [ -f "$BINARY" ]; then
    BINARY_TIME=$(stat -c %y "$BINARY" 2>/dev/null | cut -d'.' -f1)
    print_success "Binary exists: $BINARY"
    print_info "Built: $BINARY_TIME"
else
    print_error "Binary not found!"
    echo "Run: ./build.sh"
    exit 1
fi

# Check which binary is being used
WHICH_OPENCODE=$(which opencode 2>/dev/null || echo "")
if [ -n "$WHICH_OPENCODE" ]; then
    REAL_PATH=$(readlink -f "$WHICH_OPENCODE")
    if [ "$REAL_PATH" = "$(pwd)/$BINARY" ]; then
        print_success "Using correct binary: $WHICH_OPENCODE"
    else
        print_warning "Using different binary: $WHICH_OPENCODE"
        print_info "Expected: $(pwd)/$BINARY"
        print_info "Actual: $REAL_PATH"
    fi
else
    print_warning "opencode not in PATH"
    echo "You'll need to run: $(pwd)/$BINARY"
fi

echo ""
print_header "Step 3: What to Watch For"

echo "When you start OpenCode, look for:"
echo ""

if [ "$OPTION" = "Option 1" ]; then
    echo "${BOLD}Expected log message:${NC}"
    echo "  loading plugin { path: \"opencode-copilot-auth@0.0.12\" }"
    echo ""
    echo "${BOLD}This means:${NC}"
    echo "  ✓ npm plugin is loading"
    echo "  ✓ Session-based billing active"
else
    echo "${BOLD}Expected behavior:${NC}"
    echo "  ✓ Built-in plugin with conditional x-initiator"
    echo "  ✓ Session-based billing active"
fi

echo ""
print_header "Step 4: Billing Test Procedure"

echo "1. Start OpenCode and authenticate if needed"
echo ""
echo "2. Check current Copilot usage:"
echo "   → https://github.com/settings/copilot"
echo "   Note the current premium request count"
echo ""
echo "3. Send exactly 10 test messages:"
echo "   - 'hello'"
echo "   - 'test 1'"
echo "   - 'test 2'"
echo "   - ... (up to test 10)"
echo ""
echo "4. Check Copilot usage again:"
echo "   → https://github.com/settings/copilot"
echo ""
echo "5. Verify results:"
echo "   ${GREEN}✅ Success: +1 premium request (not +10)${NC}"
echo "   ${RED}❌ Failed: +10 premium requests (still per-message)${NC}"
echo ""

if [ "$OPTION" = "Option 1" ]; then
    echo "${YELLOW}If billing is still per-message:${NC}"
    echo "  1. The npm plugin might be incompatible with current Copilot API"
    echo "  2. Try Option 2 instead:"
    echo "     ./run.sh apply2 && ./build.sh && $0"
fi

echo ""
print_header "Ready to Start"

echo "Configuration: ${BOLD}$OPTION${NC}"
echo ""

read -p "Start OpenCode now? (y/N): " start

if [[ $start =~ ^[Yy]$ ]]; then
    echo ""
    print_info "Starting OpenCode..."
    echo ""
    
    if [ -n "$WHICH_OPENCODE" ]; then
        exec opencode
    else
        exec "$BINARY"
    fi
else
    echo ""
    print_info "Start manually when ready:"
    if [ -n "$WHICH_OPENCODE" ]; then
        echo "  opencode"
    else
        echo "  $BINARY"
    fi
    echo ""
fi
