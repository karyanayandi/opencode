#!/usr/bin/env bash
set -e

# Copilot Billing Fix - Interactive Menu
# This script provides an interactive menu to apply, manage, and understand
# the Copilot billing fixes for OpenCode.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BOLD}${CYAN}"
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

print_section() {
    echo -e "\n${BOLD}${MAGENTA}$1${NC}\n"
}

# Check environment
check_environment() {
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Please run this from OpenCode root directory."
        exit 1
    fi
    
    if [ ! -d "packages/opencode" ]; then
        print_error "packages/opencode not found. Are you in the right directory?"
        exit 1
    fi
}

# Detect current state
detect_state() {
    if [ ! -f "packages/opencode/src/plugin/copilot.ts" ]; then
        echo "option1"  # Option 1 applied (no built-in plugin)
    elif grep -q "Only set x-initiator for subagent requests" "packages/opencode/src/plugin/copilot.ts" 2>/dev/null; then
        echo "option2"  # Option 2 applied (modified built-in)
    else
        echo "original"  # Original (expensive) state
    fi
}

# Show current status
show_status() {
    print_section "📊 CURRENT STATUS"
    
    local state=$(detect_state)
    
    case $state in
        "option1")
            print_success "Option 1 (Simple Revert) is ACTIVE"
            echo "  • Billing: Session-based (1 request per session) ✅"
            echo "  • Plugin: opencode-copilot-auth@0.0.12 (npm)"
            echo "  • Features: Basic (no vision/enterprise)"
            echo "  • Cost: Up to 99% savings"
            ;;
        "option2")
            print_success "Option 2 (Keep Features) is ACTIVE"
            echo "  • Billing: Session-based (1 request per session) ✅"
            echo "  • Plugin: Built-in (modified)"
            echo "  • Features: All (vision, enterprise, etc.)"
            echo "  • Cost: Up to 99% savings"
            ;;
        "original")
            print_warning "ORIGINAL (Expensive) configuration is ACTIVE"
            echo "  • Billing: Per-message (1 request per message) ❌"
            echo "  • Plugin: Built-in (unmodified)"
            echo "  • Features: All"
            echo "  • Cost: Up to 100x more expensive!"
            echo ""
            print_error "⚠️  You should apply a patch to save money!"
            ;;
    esac
    
    echo ""
    
    # Check if copilot.ts exists
    if [ -f "packages/opencode/src/plugin/copilot.ts" ]; then
        print_info "Built-in plugin file exists"
    else
        print_info "Built-in plugin file removed (using npm plugin)"
    fi
    
    # Check for patch files
    echo ""
    print_info "Available patches:"
    if [ -f "$SCRIPT_DIR/revert-copilot-official-plugin.patch" ]; then
        echo "  ✓ Option 1 patch available"
    fi
    if [ -f "$SCRIPT_DIR/restore-v1110-billing-keep-features.patch" ]; then
        echo "  ✓ Option 2 patch available"
    fi
}

# Show cost comparison
show_cost_comparison() {
    print_section "💰 COST COMPARISON"
    
    echo "Example: 10-message conversation"
    echo ""
    echo "  Original (no patch):  10 premium requests  💰💰💰💰💰💰💰💰💰💰"
    echo "  Option 1 or 2:        1 premium request    💰"
    echo "  Savings:              90%"
    echo ""
    echo "Example: 100-message session"
    echo ""
    echo "  Original (no patch):  100 premium requests  💰 × 100"
    echo "  Option 1 or 2:        1 premium request     💰"
    echo "  Savings:              99%"
    echo ""
    
    local state=$(detect_state)
    if [ "$state" = "original" ]; then
        print_warning "You are currently using the expensive configuration!"
        echo "Apply Option 1 or 2 to start saving money."
    else
        print_success "You are currently using the economical configuration!"
        echo "Keep it this way after updates by reapplying patches."
    fi
}

# Show option details
show_option_details() {
    print_section "📋 OPTION DETAILS"
    
    echo -e "${BOLD}Option 1: Simple Revert${NC} (Recommended for 95% of users) ⭐"
    echo ""
    echo "  What it does:"
    echo "    • Removes built-in Copilot plugin"
    echo "    • Uses old npm package: opencode-copilot-auth@0.0.12"
    echo "    • No x-initiator header = session-based billing"
    echo ""
    echo "  Pros:"
    echo "    ✓ Simplest solution"
    echo "    ✓ Proven to work (v1.1.10 behavior)"
    echo "    ✓ Maximum reliability"
    echo ""
    echo "  Cons:"
    echo "    ✗ No Copilot Vision support"
    echo "    ✗ No GitHub Enterprise support"
    echo ""
    echo "  Best for: Regular users, cost-conscious users"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${BOLD}Option 2: Keep Features, Fix Billing${NC} (For power users) 🔧"
    echo ""
    echo "  What it does:"
    echo "    • Modifies built-in plugin"
    echo "    • Makes x-initiator conditional (only for subagents)"
    echo "    • Keeps all features intact"
    echo ""
    echo "  Pros:"
    echo "    ✓ Keeps Copilot Vision support"
    echo "    ✓ Keeps GitHub Enterprise support"
    echo "    ✓ Keeps all other features"
    echo "    ✓ Still gets session-based billing"
    echo ""
    echo "  Cons:"
    echo "    ✗ More complex patch"
    echo "    ✗ May need reapplication if copilot.ts changes"
    echo ""
    echo "  Best for: Power users, enterprise users, vision users"
}

# Apply Option 1
apply_option1() {
    print_header "APPLYING OPTION 1: Simple Revert"
    
    local state=$(detect_state)
    
    if [ "$state" = "option1" ]; then
        print_warning "Option 1 is already applied!"
        echo ""
        read -p "Do you want to reapply anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            return
        fi
        # Restore official first
        "$SCRIPT_DIR/restore-official-copilot.sh"
    elif [ "$state" = "option2" ]; then
        print_info "Option 2 is currently active. Switching to Option 1..."
        # Restore official first
        "$SCRIPT_DIR/restore-official-copilot.sh"
    fi
    
    echo ""
    print_info "Running revert-copilot-auth.sh..."
    echo ""
    
    "$SCRIPT_DIR/revert-copilot-auth.sh"
    
    echo ""
    print_success "Option 1 applied successfully!"
    echo ""
    print_warning "Next step: Rebuild OpenCode"
    echo "  Run: ${BOLD}./build.sh${NC}"
}

# Apply Option 2
apply_option2() {
    print_header "APPLYING OPTION 2: Keep Features"
    
    local state=$(detect_state)
    
    if [ "$state" = "option2" ]; then
        print_warning "Option 2 is already applied!"
        echo ""
        read -p "Do you want to reapply anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            return
        fi
        # Restore official first
        "$SCRIPT_DIR/restore-official-copilot.sh"
    elif [ "$state" = "option1" ]; then
        print_info "Option 1 is currently active. Switching to Option 2..."
        # Restore official first
        "$SCRIPT_DIR/restore-official-copilot.sh"
    fi
    
    echo ""
    print_info "Running apply-option2-billing-fix.sh..."
    echo ""
    
    "$SCRIPT_DIR/apply-option2-billing-fix.sh"
    
    echo ""
    print_success "Option 2 applied successfully!"
    echo ""
    print_warning "Next step: Rebuild OpenCode"
    echo "  Run: ${BOLD}./build.sh${NC}"
}

# Restore original
restore_original() {
    print_header "RESTORING ORIGINAL (Expensive) CONFIGURATION"
    
    local state=$(detect_state)
    
    if [ "$state" = "original" ]; then
        print_warning "Already using original configuration!"
        return
    fi
    
    echo ""
    print_warning "This will restore the expensive per-message billing."
    echo "Are you sure you want to do this?"
    echo ""
    read -p "Type 'yes' to confirm: " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        return
    fi
    
    echo ""
    "$SCRIPT_DIR/restore-official-copilot.sh"
    
    echo ""
    print_success "Original configuration restored"
    echo ""
    print_warning "Next step: Rebuild OpenCode"
    echo "  Run: ${BOLD}./build.sh${NC}"
}

# View documentation
view_docs() {
    print_header "📚 DOCUMENTATION"
    
    echo "Available documentation files:"
    echo ""
    echo "  1. START-HERE.md                           - Quick start guide (5 min)"
    echo "  2. COPILOT-FIX-SUMMARY.md                  - Overview & cost examples"
    echo "  3. COPILOT-BILLING-FIX-COMPLETE-GUIDE.md   - Complete guide"
    echo "  4. COPILOT-ANALYSIS-V1.1.10-VS-CURRENT.md  - Technical analysis"
    echo "  5. COPILOT-FILE-MANIFEST.md                - File reference"
    echo "  6. COPILOT-PATCH-VISUAL-GUIDE.md           - Visual diagrams"
    echo "  7. Go back"
    echo ""
    
    read -p "Select a file to view (1-7): " choice
    
    case $choice in
        1) less "$SCRIPT_DIR/START-HERE.md" ;;
        2) less "$SCRIPT_DIR/COPILOT-FIX-SUMMARY.md" ;;
        3) less "$SCRIPT_DIR/COPILOT-BILLING-FIX-COMPLETE-GUIDE.md" ;;
        4) less "$SCRIPT_DIR/COPILOT-ANALYSIS-V1.1.10-VS-CURRENT.md" ;;
        5) less "$SCRIPT_DIR/COPILOT-FILE-MANIFEST.md" ;;
        6) less "$SCRIPT_DIR/COPILOT-PATCH-VISUAL-GUIDE.md" ;;
        7) return ;;
        *) print_error "Invalid choice" ;;
    esac
}

# Verify installation
verify_installation() {
    print_header "🔍 INSTALLATION VERIFICATION"
    
    echo "Checking OpenCode installation..."
    echo ""
    
    local issues=0
    
    # Check which opencode binary is in use
    print_section "1. Global OpenCode Command"
    if command -v opencode &> /dev/null; then
        local opencode_path=$(which opencode)
        print_success "opencode command found"
        echo "  Location: $opencode_path"
        
        # Check version
        if [ -x "$opencode_path" ]; then
            echo -n "  Version: "
            "$opencode_path" --version 2>/dev/null || echo "Unable to determine"
        fi
        
        # Determine source
        echo -n "  Source: "
        if [[ "$opencode_path" == *"/.local/bin/"* ]]; then
            print_success "Local build (via install.sh)"
        elif [[ "$opencode_path" == *"/.bun/bin/"* ]]; then
            print_warning "Bun global install"
            echo "    ${YELLOW}ℹ${NC} Consider using local build for patched version"
            echo "    Run: ${BOLD}./install.sh${NC}"
        elif [[ "$opencode_path" == *"/node_modules/"* ]]; then
            print_warning "npm/yarn install"
            echo "    ${YELLOW}ℹ${NC} Consider using local build for patched version"
            echo "    Run: ${BOLD}./install.sh${NC}"
        else
            print_info "Unknown ($opencode_path)"
        fi
    else
        print_warning "opencode command not found in PATH"
        echo "  ${YELLOW}ℹ${NC} Run: ${BOLD}./install.sh${NC} to install locally"
        issues=$((issues + 1))
    fi
    
    # Check local build
    print_section "2. Local Build Status"
    if [ -d "packages/opencode/dist" ]; then
        print_success "Build directory exists"
        
        # Detect platform
        local platform=""
        case "$(uname -s)" in
            Linux*)     platform="linux" ;;
            Darwin*)    platform="darwin" ;;
            MINGW*|MSYS*|CYGWIN*) platform="windows" ;;
            *)          platform="unknown" ;;
        esac
        
        local arch=""
        case "$(uname -m)" in
            x86_64|amd64) arch="x64" ;;
            aarch64|arm64) arch="arm64" ;;
            *) arch="unknown" ;;
        esac
        
        if [ "$platform" != "unknown" ] && [ "$arch" != "unknown" ]; then
            local binary_path="packages/opencode/dist/opencode-${platform}-${arch}/bin/opencode"
            if [ -f "$binary_path" ]; then
                print_success "Platform binary found: opencode-${platform}-${arch}"
                echo "  Path: $binary_path"
                
                # Check if executable
                if [ -x "$binary_path" ]; then
                    print_success "Binary is executable"
                else
                    print_warning "Binary is not executable"
                    echo "  Run: ${BOLD}chmod +x $binary_path${NC}"
                fi
            else
                print_warning "Platform binary not found for ${platform}-${arch}"
                echo "  Expected: $binary_path"
                echo "  ${YELLOW}ℹ${NC} Run: ${BOLD}./build.sh${NC} to build"
                issues=$((issues + 1))
            fi
        fi
    else
        print_warning "Build directory not found"
        echo "  ${YELLOW}ℹ${NC} Run: ${BOLD}./build.sh${NC} to build"
        issues=$((issues + 1))
    fi
    
    # Check install script
    print_section "3. Install Scripts"
    if [ -f "$SCRIPT_DIR/install.sh" ] && [ -x "$SCRIPT_DIR/install.sh" ]; then
        print_success "install.sh available"
    else
        print_error "install.sh missing or not executable"
        issues=$((issues + 1))
    fi
    
    if [ -f "$SCRIPT_DIR/uninstall.sh" ] && [ -x "$SCRIPT_DIR/uninstall.sh" ]; then
        print_success "uninstall.sh available"
    else
        print_warning "uninstall.sh missing or not executable"
    fi
    
    # Summary
    echo ""
    print_section "📋 SUMMARY"
    if [ $issues -eq 0 ]; then
        print_success "Installation looks good! ✨"
    else
        print_warning "$issues issue(s) found"
        echo ""
        echo "Recommendations:"
        echo "  1. Run: ${BOLD}./build.sh${NC} to build the binary"
        echo "  2. Run: ${BOLD}./install.sh${NC} to install globally"
    fi
}

# Verify setup
verify_setup() {
    print_header "🔍 VERIFICATION"
    
    echo "Checking current setup..."
    echo ""
    
    local state=$(detect_state)
    local issues=0
    
    # Check state
    print_section "1. Configuration State"
    case $state in
        "option1")
            print_success "Option 1 is active"
            
            # Check if npm plugin will be loaded
            if grep -q "opencode-copilot-auth@0.0.12" "packages/opencode/src/plugin/index.ts"; then
                print_success "npm plugin configured correctly"
            else
                print_error "npm plugin not configured"
                issues=$((issues + 1))
            fi
            
            # Check copilot.ts doesn't exist
            if [ ! -f "packages/opencode/src/plugin/copilot.ts" ]; then
                print_success "Built-in plugin removed"
            else
                print_error "Built-in plugin still exists"
                issues=$((issues + 1))
            fi
            ;;
            
        "option2")
            print_success "Option 2 is active"
            
            # Check if modification is present
            if grep -q "Only set x-initiator for subagent requests" "packages/opencode/src/plugin/copilot.ts"; then
                print_success "Built-in plugin modified correctly"
            else
                print_error "Built-in plugin not modified correctly"
                issues=$((issues + 1))
            fi
            ;;
            
        "original")
            print_warning "Original (expensive) configuration is active"
            print_warning "Consider applying Option 1 or 2 to save money"
            ;;
    esac
    
    # Check build status
    print_section "2. Build Status"
    if [ -d "packages/opencode/dist" ]; then
        print_success "Build directory exists"
    else
        print_warning "Build directory not found - you may need to run: ./build.sh"
    fi
    
    # Check patch files
    print_section "3. Patch Files"
    if [ -f "$SCRIPT_DIR/revert-copilot-official-plugin.patch" ]; then
        print_success "Option 1 patch available"
    else
        print_error "Option 1 patch missing"
        issues=$((issues + 1))
    fi
    
    if [ -f "$SCRIPT_DIR/restore-v1110-billing-keep-features.patch" ]; then
        print_success "Option 2 patch available"
    else
        print_error "Option 2 patch missing"
        issues=$((issues + 1))
    fi
    
    # Check scripts
    print_section "4. Scripts"
    local scripts=("revert-copilot-auth.sh" "apply-option2-billing-fix.sh" "restore-official-copilot.sh")
    for script in "${scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ] && [ -x "$SCRIPT_DIR/$script" ]; then
            print_success "$script available and executable"
        else
            print_error "$script missing or not executable"
            issues=$((issues + 1))
        fi
    done
    
    # Summary
    echo ""
    print_section "📋 SUMMARY"
    if [ $issues -eq 0 ]; then
        print_success "All checks passed! ✨"
        
        if [ "$state" = "original" ]; then
            echo ""
            print_warning "Recommendation: Apply Option 1 or 2 to reduce costs"
        fi
    else
        print_error "$issues issue(s) found"
        echo ""
        echo "You may need to re-download the patch suite or fix permissions."
    fi
}

# Install locally
install_local() {
    print_header "📥 LOCAL INSTALLATION"
    
    echo "This will install the locally-built OpenCode binary globally."
    echo ""
    
    # Check if build exists
    if [ ! -d "packages/opencode/dist" ]; then
        print_error "Build not found!"
        echo ""
        echo "Please build OpenCode first:"
        echo "  ${BOLD}./build.sh${NC}"
        echo ""
        read -p "Build now? (y/N): " build
        if [[ $build =~ ^[Yy]$ ]]; then
            ./build.sh
        else
            return
        fi
    fi
    
    print_info "Installation details:"
    echo "  • Default location: ~/.local/bin/opencode"
    echo "  • Custom location: Set INSTALL_DIR environment variable"
    echo "  • Symlinks to: packages/opencode/dist/opencode-<platform>/bin/opencode"
    echo ""
    
    read -p "Install now? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo ""
        if [ -f "$SCRIPT_DIR/install.sh" ]; then
            "$SCRIPT_DIR/install.sh"
            echo ""
            print_success "Installation complete!"
            echo ""
            print_info "Verify with: ${BOLD}which opencode${NC}"
            print_info "Run with: ${BOLD}opencode${NC}"
            echo ""
            
            # Check if ~/.local/bin is in PATH
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                print_warning "~/.local/bin is not in your PATH"
                echo ""
                echo "Add to your shell config (~/.bashrc or ~/.zshrc):"
                echo "  ${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
                echo ""
                echo "Then reload: ${BOLD}source ~/.bashrc${NC} or ${BOLD}source ~/.zshrc${NC}"
            fi
        else
            print_error "install.sh not found!"
        fi
    else
        echo "Cancelled."
    fi
}

# Uninstall local
uninstall_local() {
    print_header "🗑️  UNINSTALL LOCAL"
    
    echo "This will remove the locally-installed OpenCode symlink."
    echo ""
    
    if [ -f "$SCRIPT_DIR/uninstall.sh" ]; then
        read -p "Uninstall now? (y/N): " confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            echo ""
            "$SCRIPT_DIR/uninstall.sh"
            echo ""
            print_success "Uninstallation complete!"
        else
            echo "Cancelled."
        fi
    else
        print_error "uninstall.sh not found!"
    fi
}

# Build OpenCode
build_opencode() {
    print_header "🔨 BUILD OPENCODE"
    
    local state=$(detect_state)
    
    echo "Current configuration: "
    case $state in
        "option1") echo "  ${GREEN}✓${NC} Option 1 (Session-based billing, basic features)" ;;
        "option2") echo "  ${GREEN}✓${NC} Option 2 (Session-based billing, all features)" ;;
        "original") echo "  ${YELLOW}⚠${NC} Original (Per-message billing - expensive!)" ;;
    esac
    echo ""
    
    if [ "$state" = "original" ]; then
        print_warning "You're about to build with expensive configuration!"
        echo "Consider applying Option 1 or 2 first."
        echo ""
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            return
        fi
    fi
    
    echo ""
    print_info "Building OpenCode..."
    echo ""
    
    if [ -f "$SCRIPT_DIR/build.sh" ]; then
        "$SCRIPT_DIR/build.sh"
        echo ""
        print_success "Build complete!"
        echo ""
        read -p "Install locally now? (y/N): " install
        if [[ $install =~ ^[Yy]$ ]]; then
            install_local
        fi
    else
        print_error "build.sh not found!"
        echo ""
        print_info "Manual build command:"
        echo "  ${BOLD}bun run --cwd packages/opencode script/build.ts${NC}"
    fi
}

# Test billing
test_billing() {
    print_header "🧪 BILLING TEST GUIDE"
    
    local state=$(detect_state)
    
    echo "This guide will help you verify that session-based billing is working."
    echo ""
    
    print_section "Current Configuration"
    case $state in
        "option1")
            print_success "Option 1 is active"
            echo "  Expected: 1 premium request per session"
            ;;
        "option2")
            print_success "Option 2 is active"
            echo "  Expected: 1 premium request per session"
            ;;
        "original")
            print_warning "Original (expensive) configuration"
            echo "  Expected: 1 premium request PER MESSAGE"
            echo ""
            print_error "⚠️  Apply Option 1 or 2 before testing!"
            return
            ;;
    esac
    
    echo ""
    print_section "Test Procedure"
    
    echo "1. Check current Copilot usage:"
    echo "   • Go to: https://github.com/settings/copilot"
    echo "   • Note current premium request count"
    echo ""
    
    echo "2. Start a new OpenCode session:"
    echo "   • Run: ${BOLD}opencode${NC}"
    echo "   • Send 10 simple messages (e.g., 'hello', 'test', etc.)"
    echo "   • Exit the session"
    echo ""
    
    echo "3. Check Copilot usage again:"
    echo "   • Refresh: https://github.com/settings/copilot"
    echo "   • Check premium request count"
    echo ""
    
    echo "4. Verify results:"
    echo ""
    if [ "$state" = "option1" ] || [ "$state" = "option2" ]; then
        print_success "Expected: +1 premium request (not +10)"
        echo ""
        echo "   ✅ If increased by 1: Session-based billing works!"
        echo "   ❌ If increased by 10: Something is wrong"
    fi
    echo ""
    
    print_section "Troubleshooting"
    echo "If billing is still per-message:"
    echo ""
    echo "1. Verify configuration:"
    echo "   ${BOLD}./run.sh verify${NC}"
    echo ""
    echo "2. Check that you're using the locally-built binary:"
    echo "   ${BOLD}./run.sh check-install${NC}"
    echo ""
    echo "3. Rebuild and reinstall:"
    echo "   ${BOLD}./build.sh && ./install.sh${NC}"
    echo ""
    echo "4. Check plugin loading in OpenCode logs:"
    
    if [ "$state" = "option1" ]; then
        echo "   Look for: 'loading plugin { path: \"opencode-copilot-auth@0.0.12\" }'"
    elif [ "$state" = "option2" ]; then
        echo "   Verify x-initiator is only set for subagent requests"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Quick actions
quick_fix() {
    print_header "⚡ QUICK FIX"
    
    echo "This will apply the recommended fix for most users (Option 1)."
    echo ""
    print_info "What will happen:"
    echo "  1. Switch to opencode-copilot-auth@0.0.12 (npm plugin)"
    echo "  2. Session-based billing (1 request per session)"
    echo "  3. Up to 99% cost savings"
    echo ""
    print_warning "Note: This removes vision and enterprise features"
    echo ""
    
    read -p "Continue with Quick Fix? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        apply_option1
        echo ""
        print_info "Quick Fix complete!"
        echo ""
        read -p "Build now? (y/N): " build
        if [[ $build =~ ^[Yy]$ ]]; then
            echo ""
            print_info "Running build..."
            ./build.sh
            echo ""
            read -p "Install locally now? (y/N): " install
            if [[ $install =~ ^[Yy]$ ]]; then
                install_local
            fi
        else
            print_warning "Don't forget to run: ${BOLD}./build.sh${NC}"
        fi
    else
        echo "Cancelled."
    fi
}

# Main menu
show_menu() {
    clear
    print_header "OpenCode Copilot Billing Fix - Interactive Menu"
    
    show_status
    
    echo ""
    print_section "MAIN MENU"
    
    echo "  ${BOLD}Quick Actions:${NC}"
    echo "    1. ⚡ Quick Fix (Apply + Build + Install)     - Complete setup"
    echo ""
    echo "  ${BOLD}Apply Patches:${NC}"
    echo "    2. 📦 Apply Option 1 (Simple Revert)         - Recommended for most"
    echo "    3. 🔧 Apply Option 2 (Keep Features)         - For power users"
    echo "    4. ↩️  Restore Original (Expensive)           - Undo patches"
    echo ""
    echo "  ${BOLD}Build & Install:${NC}"
    echo "    5. 🔨 Build OpenCode                         - Build binary"
    echo "    6. 📥 Install Locally                        - Install to ~/.local/bin"
    echo "    7. 🗑️  Uninstall Local                       - Remove local install"
    echo ""
    echo "  ${BOLD}Verification & Testing:${NC}"
    echo "    8. 🔍 Verify Patch Configuration             - Check patches"
    echo "    9. 🔍 Check Installation                     - Check binary location"
    echo "   10. 🧪 Billing Test Guide                     - Test session billing"
    echo ""
    echo "  ${BOLD}Information:${NC}"
    echo "   11. 💰 Show Cost Comparison                   - See savings"
    echo "   12. 📋 Show Option Details                    - Compare options"
    echo "   13. 📚 View Documentation                     - Read guides"
    echo ""
    echo "  ${BOLD}Other:${NC}"
    echo "   14. 🔄 Refresh Status                         - Update display"
    echo "    0. 🚪 Exit"
    echo ""
    
    read -p "Select an option (0-14): " choice
    
    case $choice in
        1) quick_fix ;;
        2) apply_option1 ;;
        3) apply_option2 ;;
        4) restore_original ;;
        5) build_opencode ;;
        6) install_local ;;
        7) uninstall_local ;;
        8) verify_setup ;;
        9) verify_installation ;;
        10) test_billing ;;
        11) show_cost_comparison ;;
        12) show_option_details ;;
        13) view_docs ;;
        14) return ;;
        0) 
            echo ""
            print_info "Thanks for using Copilot Billing Fix!"
            echo ""
            exit 0
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo ""
    echo ""
    read -p "Press Enter to continue..."
}

# Main script
main() {
    check_environment
    
    # If arguments provided, run non-interactively
    if [ $# -gt 0 ]; then
        case "$1" in
            "status")
                show_status
                ;;
            "apply1"|"option1")
                apply_option1
                ;;
            "apply2"|"option2")
                apply_option2
                ;;
            "restore")
                restore_original
                ;;
            "verify")
                verify_setup
                ;;
            "check-install"|"verify-install")
                verify_installation
                ;;
            "install")
                install_local
                ;;
            "uninstall")
                uninstall_local
                ;;
            "build")
                build_opencode
                ;;
            "test"|"test-billing")
                test_billing
                ;;
            "quick"|"fix")
                quick_fix
                ;;
            "help"|"--help"|"-h")
                echo "Usage: $0 [command]"
                echo ""
                echo "Commands:"
                echo "  status           - Show current status"
                echo "  apply1           - Apply Option 1 (simple revert)"
                echo "  apply2           - Apply Option 2 (keep features)"
                echo "  restore          - Restore original"
                echo "  verify           - Verify patch configuration"
                echo "  check-install    - Check installation location"
                echo "  install          - Install locally to ~/.local/bin"
                echo "  uninstall        - Remove local install"
                echo "  build            - Build OpenCode"
                echo "  test-billing     - Show billing test guide"
                echo "  quick            - Quick fix (apply + build + install)"
                echo "  help             - Show this help"
                echo ""
                echo "Run without arguments for interactive menu."
                ;;
            *)
                print_error "Unknown command: $1"
                echo "Run '$0 help' for usage."
                exit 1
                ;;
        esac
    else
        # Interactive mode
        while true; do
            show_menu
        done
    fi
}

main "$@"
