#!/usr/bin/env bash
# Quick build wrapper for OpenCode
set -e

echo "Building OpenCode..."
cd "$(dirname "$0")"

if [ -d "packages/opencode" ]; then
    bun run --cwd packages/opencode script/build.ts
else
    echo "Error: packages/opencode not found"
    exit 1
fi
