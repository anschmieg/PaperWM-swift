.PHONY: build test clean install

# Build the project
build:
	swift build

# Build in release mode
release:
	swift build -c release

# Run tests
test:
	swift test

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build

# Install deskpadctl to /usr/local/bin
install: release
	@echo "Installing deskpadctl to /usr/local/bin..."
	@sudo cp .build/release/deskpadctl /usr/local/bin/
	@sudo chmod +x /usr/local/bin/deskpadctl
	@echo "Installation complete. You can now run 'deskpadctl' from anywhere."

# Uninstall deskpadctl
uninstall:
	@echo "Removing deskpadctl from /usr/local/bin..."
	@sudo rm -f /usr/local/bin/deskpadctl
	@echo "Uninstallation complete."

# Format code (requires swift-format)
format:
	@if command -v swift-format >/dev/null 2>&1; then \
		find Sources Tests -name "*.swift" -exec swift-format -i {} \; ; \
		echo "Code formatted successfully."; \
	else \
		echo "swift-format not found. Install it with: brew install swift-format"; \
	fi

# Show help
help:
	@echo "Available targets:"
	@echo "  build     - Build the project (debug mode)"
	@echo "  release   - Build the project (release mode)"
	@echo "  test      - Run tests"
	@echo "  clean     - Remove build artifacts"
	@echo "  install   - Install deskpadctl to /usr/local/bin (requires sudo)"
	@echo "  uninstall - Remove deskpadctl from /usr/local/bin (requires sudo)"
	@echo "  format    - Format Swift code (requires swift-format)"
	@echo "  help      - Show this help message"
