#!/usr/bin/env bash
set -e

# Apply Option 2: Keep Features, Fix Billing
# This script modifies the built-in Copilot plugin to restore v1.1.10 session-based billing
# while keeping all new features (vision, enterprise support, etc.)
#
# Usage: ./apply-option2-billing-fix.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/restore-v1110-billing-keep-features.patch"

echo "======================================================================"
echo "Applying Option 2: Session-Based Billing + All Features"
echo "======================================================================"
echo ""
echo "This patch will:"
echo "  • Keep the built-in Copilot plugin"
echo "  • Keep all features (vision, enterprise, etc.)"
echo "  • Restore v1.1.10 session-based billing"
echo "  • Only send x-initiator header for subagent requests"
echo ""
echo "Changes:"
echo "  • Modifies packages/opencode/src/plugin/copilot.ts"
echo "  • Makes x-initiator conditional (only for subagents)"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Are you in the OpenCode root directory?"
    exit 1
fi

if [ ! -d "packages/opencode" ]; then
    echo "Error: packages/opencode directory not found."
    exit 1
fi

# Check if patch file exists
if [ ! -f "$PATCH_FILE" ]; then
    echo "Error: Patch file not found at $PATCH_FILE"
    exit 1
fi

# Check if copilot.ts exists
if [ ! -f "packages/opencode/src/plugin/copilot.ts" ]; then
    echo "Error: copilot.ts not found. Option 2 requires the built-in plugin."
    echo ""
    echo "It looks like you may have already applied Option 1 (simple revert)."
    echo "To use Option 2, first restore the official plugin:"
    echo "  ./restore-official-copilot.sh"
    echo ""
    exit 1
fi

echo "Checking if patch can be applied..."

# Check if already applied
if grep -q "Only set x-initiator for subagent requests" packages/opencode/src/plugin/copilot.ts; then
    echo "✓ Patch already applied!"
    echo ""
    echo "The billing fix is already in place."
    echo "Your Copilot requests should be counted per session, not per message."
    exit 0
fi

# Apply the patch
if git apply --check "$PATCH_FILE" 2>/dev/null; then
    git apply "$PATCH_FILE"
    echo "✓ Patch applied successfully!"
else
    echo ""
    echo "Warning: Patch cannot be applied cleanly. Trying with 3-way merge..."
    if git apply --3way "$PATCH_FILE" 2>/dev/null; then
        echo "✓ Patch applied with 3-way merge!"
        echo ""
        echo "Note: There may be conflicts. Please review the changes:"
        git diff packages/opencode/src/plugin/copilot.ts
    else
        echo ""
        echo "Error: Failed to apply patch automatically."
        echo ""
        echo "This might happen if:"
        echo "  - copilot.ts has changed significantly in newer versions"
        echo "  - You have local modifications"
        echo ""
        echo "Manual fix:"
        echo "  Edit packages/opencode/src/plugin/copilot.ts around line 121-122"
        echo ""
        echo "  Change from:"
        echo '    "x-initiator": isAgent ? "agent" : "user",'
        echo ""
        echo "  To:"
        echo '    ...(isAgent ? { "x-initiator": "agent" } : {}),'
        echo ""
        exit 1
    fi
fi

echo ""
echo "======================================================================"
echo "Option 2 Applied Successfully!"
echo "======================================================================"
echo ""
echo "Changes made:"
echo "  ✓ x-initiator header now only sent for subagent requests"
echo "  ✓ Regular user messages won't trigger per-message billing"
echo "  ✓ All features (vision, enterprise) still available"
echo ""
echo "Next steps:"
echo "  1. Rebuild OpenCode: bun run build"
echo "  2. Restart OpenCode"
echo "  3. Monitor your GitHub Copilot usage dashboard"
echo ""
echo "Expected billing:"
echo "  • Before: 1 premium request per message ❌"
echo "  • After:  1 premium request per session ✅"
echo ""
echo "To verify the change:"
echo "  grep -A3 'x-initiator' packages/opencode/src/plugin/copilot.ts"
echo ""
echo "To revert this patch:"
echo "  git checkout packages/opencode/src/plugin/copilot.ts"
echo "  bun run build"
echo ""
