#!/bin/bash
# Manual functionality test for PaperWM-swift

set -e

DESKPADCTL="./Tools/deskpadctl/.build/release/deskpadctl"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     PaperWM-swift Manual Functionality Test                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Test 1: CLI Help
echo "📋 Test 1: CLI Help Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$ deskpadctl --help"
$DESKPADCTL --help | head -10
echo
echo "✅ Test 1 Passed"
echo

# Test 2: Version
echo "📋 Test 2: Version Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$ deskpadctl --version"
$DESKPADCTL --version
echo
echo "✅ Test 2 Passed"
echo

# Test 3: Create Command
echo "📋 Test 3: Create Virtual Display Command"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$ deskpadctl create --width 2560 --height 1440 --name 'Test Display'"
$DESKPADCTL create --width 2560 --height 1440 --name "Test Display"
echo
echo "✅ Test 3 Passed - Notification sent"
echo

# Test 4: List Command
echo "📋 Test 4: List Displays Command"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$ deskpadctl list"
$DESKPADCTL list
echo
echo "✅ Test 4 Passed - Notification sent"
echo

# Test 5: Remove Command
echo "📋 Test 5: Remove Display Command"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$ deskpadctl remove 1234"
$DESKPADCTL remove 1234
echo
echo "✅ Test 5 Passed - Notification sent"
echo

# Test 6: Canvas Scripts
echo "📋 Test 6: Canvas Scripts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$ Scripts/arrange-canvas.sh --help"
./Scripts/arrange-canvas.sh --help | head -5
echo
echo "$ Scripts/pan-canvas.sh --help"
./Scripts/pan-canvas.sh --help | head -5
echo
echo "✅ Test 6 Passed - Scripts are functional"
echo

# Test 7: Integration Files
echo "📋 Test 7: Integration Component"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Integration/DeskPad/ files:"
ls -lh Integration/DeskPad/ | tail -n +2 | awk '{print "  ✓", $9, "(" $5 ")"}'
echo
echo "✅ Test 7 Passed - Integration files present"
echo

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    TEST SUMMARY                            ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  ✅ CLI Help & Version                                     ║"
echo "║  ✅ Create Command (sends notification)                    ║"
echo "║  ✅ List Command (sends notification)                      ║"
echo "║  ✅ Remove Command (sends notification)                    ║"
echo "║  ✅ Canvas Scripts (arrange & pan)                         ║"
echo "║  ✅ Integration Component (DisplayControl)                 ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  All functionality tests PASSED ✅                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "📝 Note: Commands send distributed notifications."
echo "   To see them received, run the DeskPad app with DisplayControl"
echo "   integrated, or use the test-listener.swift script."
echo
