# Makefile for pack-manager.nvim

.PHONY: test test-watch install-deps clean lint

# Default target
all: test

# Install testing dependencies
install-deps:
	@echo "Installing testing dependencies..."
	@if command -v luarocks > /dev/null 2>&1; then \
		luarocks install busted; \
		luarocks install luacov; \
	else \
		echo "Warning: luarocks not found. Please install luarocks and run 'make install-deps'"; \
	fi

# Run tests
test:
	@echo "Running tests..."
	@if command -v busted > /dev/null 2>&1; then \
		busted --verbose tests/; \
	else \
		echo "Error: busted not found. Run 'make install-deps' first"; \
		exit 1; \
	fi

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	@if command -v busted > /dev/null 2>&1; then \
		busted --verbose --coverage tests/; \
		if command -v luacov > /dev/null 2>&1; then \
			luacov; \
		fi \
	else \
		echo "Error: busted not found. Run 'make install-deps' first"; \
		exit 1; \
	fi

# Watch tests (requires entr or similar)
test-watch:
	@echo "Watching files for changes..."
	@if command -v find > /dev/null 2>&1 && command -v entr > /dev/null 2>&1; then \
		find lua tests -name "*.lua" | entr -c make test; \
	else \
		echo "Error: find and entr required for watch mode"; \
		exit 1; \
	fi

# Lint Lua files
lint:
	@echo "Linting Lua files..."
	@if command -v luacheck > /dev/null 2>&1; then \
		luacheck lua/ tests/ --globals vim; \
	else \
		echo "Warning: luacheck not found. Install with 'luarocks install luacheck'"; \
	fi

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f luacov.stats.out luacov.report.out

# Help
help:
	@echo "Available targets:"
	@echo "  test          - Run all tests"
	@echo "  test-coverage - Run tests with coverage report"
	@echo "  test-watch    - Watch files and run tests on changes"
	@echo "  lint          - Lint Lua files with luacheck"
	@echo "  install-deps  - Install testing dependencies"
	@echo "  clean         - Clean generated files"
	@echo "  help          - Show this help message"