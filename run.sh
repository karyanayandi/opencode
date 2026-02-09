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
    echo "  Run: ${BOLD}bun run build${NC}"
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
    echo "  Run: ${BOLD}bun run build${NC}"
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
    echo "  Run: ${BOLD}bun run build${NC}"
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
        print_warning "Build directory not found - you may need to run: bun run build"
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
            bun run build
        else
            print_warning "Don't forget to run: ${BOLD}bun run build${NC}"
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
    echo "    1. ⚡ Quick Fix (Apply Option 1 + Build)        - Fastest solution"
    echo ""
    echo "  ${BOLD}Apply Patches:${NC}"
    echo "    2. 📦 Apply Option 1 (Simple Revert)           - Recommended for most"
    echo "    3. 🔧 Apply Option 2 (Keep Features)           - For power users"
    echo "    4. ↩️  Restore Original (Expensive)             - Undo patches"
    echo ""
    echo "  ${BOLD}Information:${NC}"
    echo "    5. 💰 Show Cost Comparison                     - See savings"
    echo "    6. 📋 Show Option Details                      - Compare options"
    echo "    7. 🔍 Verify Current Setup                     - Check everything"
    echo "    8. 📚 View Documentation                       - Read guides"
    echo ""
    echo "  ${BOLD}Other:${NC}"
    echo "    9. 🔄 Refresh Status                           - Update display"
    echo "    0. 🚪 Exit"
    echo ""
    
    read -p "Select an option (0-9): " choice
    
    case $choice in
        1) quick_fix ;;
        2) apply_option1 ;;
        3) apply_option2 ;;
        4) restore_original ;;
        5) show_cost_comparison ;;
        6) show_option_details ;;
        7) verify_setup ;;
        8) view_docs ;;
        9) return ;;
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
            "quick"|"fix")
                quick_fix
                ;;
            "help"|"--help"|"-h")
                echo "Usage: $0 [command]"
                echo ""
                echo "Commands:"
                echo "  status      - Show current status"
                echo "  apply1      - Apply Option 1 (simple revert)"
                echo "  apply2      - Apply Option 2 (keep features)"
                echo "  restore     - Restore original"
                echo "  verify      - Verify setup"
                echo "  quick       - Quick fix (apply option 1)"
                echo "  help        - Show this help"
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
