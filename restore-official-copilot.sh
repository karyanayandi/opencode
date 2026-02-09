#!/usr/bin/env bash
set -e

# Restore Official Copilot Plugin Script
# This script reverts the patch and restores the official built-in Copilot authentication.
#
# Usage: ./restore-official-copilot.sh

echo "======================================================================"
echo "Restoring Official Copilot Plugin"
echo "======================================================================"
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

echo "This will restore the official built-in Copilot plugin."
echo ""
echo "Checking git status..."

# Check if files have been modified
if git diff --quiet packages/opencode/src/plugin/index.ts packages/opencode/src/plugin/copilot.ts 2>/dev/null; then
    echo "No changes detected. Official plugin may already be in place."
    exit 0
fi

echo ""
echo "Restoring files from git..."

git checkout packages/opencode/src/plugin/copilot.ts packages/opencode/src/plugin/index.ts

echo "✓ Files restored!"
echo ""
echo "======================================================================"
echo "Official Plugin Restored"
echo "======================================================================"
echo ""
echo "Next steps:"
echo "  1. Rebuild OpenCode: bun run --cwd packages/opencode script/build.ts"
echo "  2. Restart OpenCode"
echo "  3. You may need to re-authenticate with GitHub Copilot"
echo ""
echo "Note: The official plugin uses more premium requests."
echo "To switch back to the old plugin, run: ./revert-copilot-auth.sh"
echo ""
