.PHONY: docs docs-serve docs-clean test test-unit test-integration test-watch test-install help

# Generate all documentation
docs:
	@echo "🔧 Generating documentation..."
	@./scripts/generate_docs.sh

# Serve documentation locally (if you have a local server)
docs-serve: docs
	@echo "🌐 Serving documentation..."
	@if command -v python3 >/dev/null 2>&1; then \
		echo "Starting local server at http://localhost:8000"; \
		cd docs/generated && python3 -m http.server 8000; \
	else \
		echo "❌ Python3 not found. Please install Python3 to serve docs locally."; \
	fi

# Clean generated documentation
docs-clean:
	@echo "🧹 Cleaning documentation..."
	@rm -rf docs/generated doc/terrareg.txt

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
	@echo "  docs         - Generate all documentation"
	@echo "  docs-serve   - Generate and serve documentation locally"
	@echo "  docs-clean   - Clean generated documentation"
	@echo "  test-install - Install test dependencies"
	@echo "  test         - Run all tests"
	@echo "  test-unit    - Run unit tests only"
	@echo "  test-integration - Run integration tests with Neovim"
	@echo "  test-coverage - Run tests with coverage report"
	@echo "  test-watch   - Watch files and run tests on changes"
	@echo "  lint         - Run luacheck linting"
	@echo "  format       - Format code with stylua"
	@echo "  check        - Run all quality checks (lint, format, test)"
	@echo "  help         - Show this help message"
