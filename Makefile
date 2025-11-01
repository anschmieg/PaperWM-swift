# PaperWM-swift Makefile
# Build and test utilities for PaperWM-swift canvas application

.PHONY: all build test clean install help submodule-update deskpadctl

# Default target
all: build

# Initialize and update submodules
submodule-update:
	git submodule update --init --recursive

# Build all tools
build: deskpadctl
	@echo "Building all tools..."

# Build deskpadctl CLI
deskpadctl:
	@echo "Building deskpadctl..."
	cd Tools/deskpadctl && swift build -c release

# Run tests
test:
	@echo "Running integration tests..."
	./Tests/integration-test.sh
	@echo "All tests passed!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cd Tools/deskpadctl && swift package clean || true
	rm -rf .build

# Install tools to /usr/local/bin
install: build
	@echo "Installing tools..."
	install -m 755 Tools/deskpadctl/.build/release/deskpadctl /usr/local/bin/

# Show help
help:
	@echo "PaperWM-swift Makefile targets:"
	@echo "  all              - Build all tools (default)"
	@echo "  build            - Build all tools"
	@echo "  deskpadctl       - Build deskpadctl CLI"
	@echo "  test             - Run all tests"
	@echo "  clean            - Clean build artifacts"
	@echo "  install          - Install tools to /usr/local/bin"
	@echo "  submodule-update - Update git submodules"
	@echo "  help             - Show this help message"
