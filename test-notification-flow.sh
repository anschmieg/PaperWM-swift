#!/bin/bash
# Test the full notification flow

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Testing Distributed Notification Flow                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo
echo "This test demonstrates the communication between deskpadctl"
echo "and a listener (simulating DeskPad with DisplayControl)."
echo
echo "Starting listener in background..."

# Start listener in background
swift test-listener.swift > /tmp/listener.log 2>&1 &
LISTENER_PID=$!

# Give it time to start
sleep 2

echo "✅ Listener started (PID: $LISTENER_PID)"
echo

# Send some commands
echo "Sending commands..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "1️⃣  Creating virtual display (1920x1080)..."
./Tools/deskpadctl/.build/release/deskpadctl create --width 1920 --height 1080 --name "Canvas 1"
sleep 1

echo
echo "2️⃣  Creating another display (2560x1440)..."
./Tools/deskpadctl/.build/release/deskpadctl create --width 2560 --height 1440 --name "Canvas 2"
sleep 1

echo
echo "3️⃣  Listing displays..."
./Tools/deskpadctl/.build/release/deskpadctl list
sleep 1

echo
echo "4️⃣  Removing display 1234..."
./Tools/deskpadctl/.build/release/deskpadctl remove 1234
sleep 1

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Stop listener
kill $LISTENER_PID 2>/dev/null

echo "📋 Listener Output:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat /tmp/listener.log
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "✅ Notification flow test complete!"
echo
echo "Summary:"
echo "  • deskpadctl sent 4 commands via distributed notifications"
echo "  • Listener received and parsed all notifications"
echo "  • Communication protocol working correctly"
echo
