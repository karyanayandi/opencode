#!/usr/bin/env bash
set -e

# Copilot Auth Revert Script
# This script reverts OpenCode to use the old opencode-copilot-auth npm plugin
# instead of the official built-in Copilot authentication plugin.
#
# Usage: ./revert-copilot-auth.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/revert-copilot-official-plugin.patch"

echo "======================================================================"
echo "Reverting Copilot Authentication to Old npm Plugin"
echo "======================================================================"
echo ""
echo "This will:"
echo "  1. Remove the built-in CopilotAuthPlugin from packages/opencode/src/plugin/copilot.ts"
echo "  2. Restore opencode-copilot-auth@0.0.12 as an external npm plugin"
echo ""
echo "Benefits:"
echo "  - Reduces premium request usage"
echo "  - Uses the older, more economical authentication method"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Are you in the OpenCode root directory?"
    exit 1
fi

if [ ! -d "packages/opencode" ]; then
    echo "Error: packages/opencode directory not found. Are you in the OpenCode root directory?"
    exit 1
fi

# Check if patch file exists
if [ ! -f "$PATCH_FILE" ]; then
    echo "Error: Patch file not found at $PATCH_FILE"
    exit 1
fi

echo "Checking current state..."

# Check if copilot.ts exists (meaning the official plugin is present)
if [ ! -f "packages/opencode/src/plugin/copilot.ts" ]; then
    echo "Info: copilot.ts not found. The official plugin may already be removed."
    echo "Checking plugin/index.ts..."
    
    if grep -q "opencode-copilot-auth@0.0.12" packages/opencode/src/plugin/index.ts; then
        echo "Success: Old plugin configuration already in place!"
        exit 0
    else
        echo "Warning: Unable to determine current state. Proceeding with patch..."
    fi
fi

echo ""
echo "Applying patch..."

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
        git diff --cached
    else
        echo ""
        echo "Error: Failed to apply patch automatically."
        echo ""
        echo "This might happen if:"
        echo "  - The code has changed significantly in newer versions"
        echo "  - The patch has already been applied"
        echo "  - You have local modifications"
        echo ""
        echo "You can try applying manually:"
        echo "  1. Review the patch file: $PATCH_FILE"
        echo "  2. Remove packages/opencode/src/plugin/copilot.ts"
        echo "  3. Edit packages/opencode/src/plugin/index.ts:"
        echo "     - Remove: import { CopilotAuthPlugin } from \"./copilot\""
        echo "     - Add 'opencode-copilot-auth@0.0.12' to BUILTIN array"
        echo "     - Remove CopilotAuthPlugin from INTERNAL_PLUGINS array"
        exit 1
    fi
fi

echo ""
echo "======================================================================"
echo "Patch Applied Successfully!"
echo "======================================================================"
echo ""
echo "Next steps:"
echo "  1. Rebuild OpenCode: bun run --cwd packages/opencode script/build.ts (or your build command)"
echo "  2. Restart OpenCode"
echo "  3. Re-authenticate with GitHub Copilot if needed"
echo ""
echo "To revert this patch (go back to official plugin):"
echo "  git checkout packages/opencode/src/plugin/copilot.ts packages/opencode/src/plugin/index.ts"
echo ""
