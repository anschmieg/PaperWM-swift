#!/bin/bash
# integration-test.sh
# Integration tests for PaperWM-swift components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DESKPADCTL="$PROJECT_ROOT/Tools/deskpadctl/.build/debug/deskpadctl"

echo "🧪 Running PaperWM-swift Integration Tests"
echo "=========================================="
echo ""

# Test 1: Verify deskpadctl exists and is executable
echo "Test 1: Verify deskpadctl binary"
if [ -f "$DESKPADCTL" ]; then
    echo "  ✓ deskpadctl binary found at $DESKPADCTL"
else
    echo "  ✗ deskpadctl binary not found"
    echo "  Run 'make build' first"
    exit 1
fi

# Test 2: Verify deskpadctl --help works
echo ""
echo "Test 2: Verify deskpadctl --help"
if "$DESKPADCTL" --help > /dev/null 2>&1; then
    echo "  ✓ deskpadctl --help works"
else
    echo "  ✗ deskpadctl --help failed"
    exit 1
fi

# Test 3: Verify subcommands exist
echo ""
echo "Test 3: Verify deskpadctl subcommands"
for cmd in create remove list; do
    if "$DESKPADCTL" "$cmd" --help > /dev/null 2>&1; then
        echo "  ✓ $cmd subcommand exists"
    else
        echo "  ✗ $cmd subcommand failed"
        exit 1
    fi
done

# Test 4: Verify scripts are executable
echo ""
echo "Test 4: Verify scripts are executable"
for script in arrange-canvas.sh pan-canvas.sh; do
    if [ -x "$PROJECT_ROOT/Scripts/$script" ]; then
        echo "  ✓ $script is executable"
    else
        echo "  ✗ $script is not executable"
        exit 1
    fi
done

# Test 5: Test arrange-canvas.sh --help
echo ""
echo "Test 5: Verify arrange-canvas.sh --help"
if "$PROJECT_ROOT/Scripts/arrange-canvas.sh" --help > /dev/null 2>&1; then
    echo "  ✓ arrange-canvas.sh --help works"
else
    echo "  ✗ arrange-canvas.sh --help failed"
    exit 1
fi

# Test 6: Test pan-canvas.sh --help
echo ""
echo "Test 6: Verify pan-canvas.sh --help"
if "$PROJECT_ROOT/Scripts/pan-canvas.sh" --help > /dev/null 2>&1; then
    echo "  ✓ pan-canvas.sh --help works"
else
    echo "  ✗ pan-canvas.sh --help failed"
    exit 1
fi

# Test 7: Verify DisplayControl.swift exists
echo ""
echo "Test 7: Verify DisplayControl component"
if [ -f "$PROJECT_ROOT/submodules/DeskPad/DeskPad/DisplayControl.swift" ]; then
    echo "  ✓ DisplayControl.swift exists"
else
    echo "  ✗ DisplayControl.swift not found"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All integration tests passed!"
echo ""
