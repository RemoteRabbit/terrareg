#!/bin/bash
# Watch Lua files and auto-regenerate API docs during development

set -e

echo "👀 Watching Lua files for changes..."
echo "🤖 API docs will auto-regenerate when you modify code"
echo "📖 Start the docs dev server with: make docs-dev"
echo ""

# Check if entr is available
if ! command -v entr &> /dev/null; then
    echo "❌ 'entr' not found. Install it to enable file watching:"
    echo "   Ubuntu/Debian: sudo apt install entr"
    echo "   macOS: brew install entr"
    echo "   Arch: pacman -S entr"
    exit 1
fi

# Watch Lua files and regenerate docs on changes
find lua/ -name "*.lua" | entr -c sh -c '
    echo "🔄 Lua file changed, regenerating API docs..."
    lua scripts/generate-api-docs.lua
    echo "✅ API docs updated!"
    echo ""
'
