#!/bin/bash

# Generate documentation for terrareg.nvim
# Usage: ./generate_docs.sh

set -e  # Fail on errors
echo "🔧 Generating documentation for terrareg.nvim..."

# Set up luarocks PATH
if [ -d "$HOME/.luarocks/bin" ]; then
    export PATH="$HOME/.luarocks/bin:$PATH"
fi

# Check if ldoc is installed
if ! command -v ldoc &> /dev/null; then
    echo "❌ LDoc is not installed. Installing via LuaRocks..."
    if command -v luarocks &> /dev/null; then
        luarocks install ldoc
        # Update PATH again after installation
        if [ -d "$HOME/.luarocks/bin" ]; then
            export PATH="$HOME/.luarocks/bin:$PATH"
        fi
    else
        echo "❌ LuaRocks is not installed. Please install LuaRocks and LDoc manually."
        exit 1
    fi
fi

# Clean old docs
echo "🧹 Cleaning old documentation..."
rm -rf docs/generated

# Generate LDoc documentation
echo "📖 Generating LDoc documentation..."
ldoc .

# Fix LDoc index file name
if [ -f "docs/generated/..html" ]; then
    cp "docs/generated/..html" "docs/generated/index.html"
    echo "🔗 Created index.html for proper web serving"
fi

# Generate enhanced documentation if Neovim is available
if command -v nvim &> /dev/null; then
    echo "📝 Generating enhanced documentation..."
    nvim --headless -c "lua dofile('scripts/generate_vimdoc_dynamic.lua')" -c "qa!" 2>/dev/null || {
        echo "⚠️  Dynamic vimdoc failed, using fallback"
        nvim --headless -c "lua dofile('scripts/generate_vimdoc.lua')" -c "qa!" 2>/dev/null || true
    }
    nvim --headless -c "lua dofile('scripts/extract_examples.lua')" -c "qa!" 2>/dev/null || true
    nvim --headless -c "lua dofile('scripts/analyze_compatibility.lua')" -c "qa!" 2>/dev/null || true
    nvim --headless -c "lua dofile('scripts/generate_config_schema.lua')" -c "qa!" 2>/dev/null || true
fi

echo "✅ Documentation generated successfully!"
echo "📁 LDoc: docs/generated/"
echo "📁 Vimdoc: doc/terrareg.txt"
