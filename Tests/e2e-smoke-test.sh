#!/bin/bash
# e2e-smoke-test.sh
# End-to-end smoke test for PaperWM-swift
# Tests the complete workflow of creating and managing virtual displays

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DESKPADCTL="$PROJECT_ROOT/Tools/deskpadctl/.build/debug/deskpadctl"

echo "🔥 Running PaperWM-swift E2E Smoke Test"
echo "========================================"
echo ""

# Smoke Test 1: Build verification
echo "Smoke Test 1: Build verification"
echo "  Building deskpadctl..."
cd "$PROJECT_ROOT/Tools/deskpadctl"
swift build > /dev/null 2>&1
echo "  ✓ Build successful"

# Smoke Test 2: Unit tests
echo ""
echo "Smoke Test 2: Unit tests"
echo "  Running unit tests..."
swift test > /dev/null 2>&1
echo "  ✓ Unit tests passed"

# Smoke Test 3: CLI functionality (non-macOS simulation)
echo ""
echo "Smoke Test 3: CLI functionality"
echo "  Testing create command..."
output=$("$DESKPADCTL" create --width 1920 --height 1080 2>&1 || true)
if [[ $output == *"Create command sent successfully"* ]] || [[ $output == *"Warning: DistributedNotificationCenter not available"* ]]; then
    echo "  ✓ Create command works"
else
    echo "  ✗ Create command failed"
    echo "  Output: $output"
    exit 1
fi

echo "  Testing list command..."
output=$("$DESKPADCTL" list 2>&1 || true)
if [[ $output == *"List command sent successfully"* ]] || [[ $output == *"Warning: DistributedNotificationCenter not available"* ]]; then
    echo "  ✓ List command works"
else
    echo "  ✗ List command failed"
    exit 1
fi

echo "  Testing remove command..."
output=$("$DESKPADCTL" remove 1234 2>&1 || true)
if [[ $output == *"Remove command sent successfully"* ]] || [[ $output == *"Warning: DistributedNotificationCenter not available"* ]]; then
    echo "  ✓ Remove command works"
else
    echo "  ✗ Remove command failed"
    exit 1
fi

# Smoke Test 4: Scripts
echo ""
echo "Smoke Test 4: Scripts"
echo "  Testing arrange-canvas.sh..."
cd "$PROJECT_ROOT"
output=$(Scripts/arrange-canvas.sh --canvas-width 3840 --canvas-height 1080 2>&1)
if [[ $output == *"Canvas arrangement planned"* ]]; then
    echo "  ✓ arrange-canvas.sh works"
else
    echo "  ✗ arrange-canvas.sh failed"
    exit 1
fi

echo "  Testing pan-canvas.sh..."
output=$(Scripts/pan-canvas.sh right 2>&1)
if [[ $output == *"Canvas panned successfully"* ]]; then
    echo "  ✓ pan-canvas.sh works"
else
    echo "  ✗ pan-canvas.sh failed"
    exit 1
fi

# Smoke Test 5: File structure
echo ""
echo "Smoke Test 5: Project structure"
required_files=(
    "Makefile"
    ".github/workflows/ci.yml"
    "README.md"
    "Tools/deskpadctl/Package.swift"
    "Scripts/arrange-canvas.sh"
    "Scripts/pan-canvas.sh"
    "Integration/DeskPad/DisplayControl.swift"
    "Integration/DeskPad/DISPLAYCONTROL_INTEGRATION.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ] || [ -d "$PROJECT_ROOT/$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ $file missing"
        exit 1
    fi
done

echo ""
echo "========================================"
echo "✅ All E2E smoke tests passed!"
echo ""
echo "Summary:"
echo "  - Build: ✓"
echo "  - Unit Tests: ✓"
echo "  - CLI Commands: ✓"
echo "  - Scripts: ✓"
echo "  - Project Structure: ✓"
echo ""
