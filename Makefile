.PHONY: docs docs-serve docs-dev docs-build docs-clean docs-install docs-generate test test-unit test-integration test-watch test-install help

# Generate documentation (VitePress)
docs: docs-generate docs-install
	@echo "🚀 Building documentation with VitePress..."
	@cd docs && npm run build
	@echo "✅ Documentation built successfully!"
	@echo "📁 Output: docs/.vitepress/dist/"

# Generate API docs from source code
docs-generate:
	@echo "🤖 Generating API documentation from source code..."
	@lua scripts/generate-api-docs.lua

# Install documentation dependencies
docs-install:
	@echo "📦 Installing documentation dependencies..."
	@cd docs && if [ ! -d node_modules ]; then npm install; fi

# Serve documentation locally for development
docs-dev: docs-generate docs-install
	@echo "🌐 Starting development server..."
	@echo "📖 Documentation will be available at http://localhost:5173"
	@echo "💡 Run 'make docs-watch' in another terminal to auto-update API docs"
	@cd docs && npm run dev

# Watch Lua files and auto-regenerate API docs
docs-watch:
	@echo "👀 Starting file watcher for API documentation..."
	@./scripts/watch-docs.sh

# Build and serve production documentation locally
docs-serve: docs
	@echo "🌐 Serving production documentation..."
	@echo "📖 Documentation available at http://localhost:4173"
	@cd docs && npm run preview

# Clean generated documentation
docs-clean:
	@echo "🧹 Cleaning documentation..."
	@rm -rf docs/.vitepress/dist docs/.vitepress/cache docs/node_modules

# Install test dependencies
test-install:
	@echo "📦 Installing test dependencies..."
	@if command -v luarocks >/dev/null 2>&1; then \
		luarocks install --local busted; \
		luarocks install --local luacov; \
	else \
		echo "❌ LuaRocks not found. Please install LuaRocks first."; \
		exit 1; \
	fi

# Run all tests
test: test-unit test-integration

# Run unit tests only
test-unit:
	@echo "🧪 Running unit tests..."
	@export PATH="$$HOME/.luarocks/bin:$$PATH"; \
	export LUA_PATH="$$HOME/.luarocks/share/lua/5.4/?.lua;$$HOME/.luarocks/share/lua/5.4/?/init.lua;$$LUA_PATH"; \
	export LUA_CPATH="$$HOME/.luarocks/lib/lua/5.4/?.so;$$LUA_CPATH"; \
	if command -v busted >/dev/null 2>&1; then \
		busted test/terrareg_spec.lua test/config_validation_spec.lua --verbose; \
	else \
		echo "❌ Busted not found. Run 'make test-install' first."; \
		exit 1; \
	fi

# Run integration tests with Neovim
test-integration:
	@echo "🔗 Running integration tests..."
	@if command -v nvim >/dev/null 2>&1; then \
		if command -v busted >/dev/null 2>&1; then \
			nvim --headless -u test/minimal_init.lua -c "lua require('plenary.test_harness').test_directory('test/', {minimal_init = 'test/minimal_init.lua'})" -c "qa!"; \
		elif [ -f "$$HOME/.luarocks/bin/busted" ]; then \
			nvim --headless -u test/minimal_init.lua -c "lua package.path = os.getenv('HOME') .. '/.luarocks/share/lua/5.1/?.lua;' .. package.path" -c "lua require('busted.runner')({standalone = false})" test/integration_spec.lua -c "qa!"; \
		else \
			echo "❌ Busted not found. Run 'make test-install' first."; \
			exit 1; \
		fi \
	else \
		echo "❌ Neovim not found. Please install Neovim to run integration tests."; \
		exit 1; \
	fi

# Run tests with coverage
test-coverage:
	@echo "📊 Running tests with coverage..."
	@if command -v busted >/dev/null 2>&1; then \
		busted --coverage test/; \
	elif [ -f "$$HOME/.luarocks/bin/busted" ]; then \
		$$HOME/.luarocks/bin/busted --coverage test/; \
	else \
		echo "❌ Busted not found. Run 'make test-install' first."; \
		exit 1; \
	fi

# Watch tests for changes (if entr is available)
test-watch:
	@echo "👀 Watching for changes..."
	@if command -v entr >/dev/null 2>&1; then \
		find lua/ test/ -name "*.lua" | entr -c make test-unit; \
	else \
		echo "❌ entr not found. Install entr for watch functionality."; \
		echo "    On Ubuntu/Debian: apt install entr"; \
		echo "    On macOS: brew install entr"; \
		exit 1; \
	fi

# Run linting
lint:
	@echo "🔍 Running linting..."
	@if command -v luacheck >/dev/null 2>&1; then \
		luacheck lua/ test/; \
	else \
		echo "❌ luacheck not found. Install with: luarocks install luacheck"; \
		exit 1; \
	fi

# Format code
format:
	@echo "✨ Formatting code..."
	@if command -v stylua >/dev/null 2>&1; then \
		stylua lua/ test/; \
	else \
		echo "❌ stylua not found. Install from: https://github.com/JohnnyMorganz/StyLua"; \
		exit 1; \
	fi

# Run all quality checks
check: lint format test

# Show help
help:
	@echo "Available targets:"
	@echo ""
	@echo "📖 Documentation:"
	@echo "  docs            - Build documentation with VitePress (auto-generates API docs)"
	@echo "  docs-generate   - Generate API docs from source code"
	@echo "  docs-dev        - Start development server (http://localhost:5173)"
	@echo "  docs-watch      - Watch Lua files and auto-regenerate API docs"
	@echo "  docs-serve      - Build and serve production docs (http://localhost:4173)"
	@echo "  docs-install    - Install documentation dependencies"
	@echo "  docs-clean      - Clean generated documentation"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test-install    - Install test dependencies"
	@echo "  test            - Run all tests"
	@echo "  test-unit       - Run unit tests only"
	@echo "  test-integration - Run integration tests with Neovim"
	@echo "  test-coverage   - Run tests with coverage report"
	@echo "  test-watch      - Watch files and run tests on changes"
	@echo ""
	@echo "🔧 Code Quality:"
	@echo "  lint            - Run luacheck linting"
	@echo "  format          - Format code with stylua"
	@echo "  check           - Run all quality checks (lint, format, test)"
	@echo ""
	@echo "❓ Help:"
	@echo "  help            - Show this help message"
