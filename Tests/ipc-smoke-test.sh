#!/usr/bin/env bash
# Quick IPC smoke test for PaperWM-swift
# - Starts the test-listener (which also opens a unix domain socket at /tmp/deskpad.sock)
# - Runs a few create/list/remove commands against the socket-enabled CLI
# - Measures round-trip times using Perl Time::HiRes (available on macOS)

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LISTENER="$REPO_ROOT/test-listener.swift"
CLI="$REPO_ROOT/Tools/deskpadctl/.build/release/deskpadctl"
SOCK=/tmp/deskpad.sock
LOG=/tmp/deskpad-listener.log
PIDFILE=/tmp/deskpad-listener.pid

now() { perl -MTime::HiRes=time -e 'printf("%.6f", time)'; }

echo "== IPC smoke test =="

# cleanup
rm -f "$LOG" "$PIDFILE" "$SOCK" /tmp/deskpad_response_*.json || true

echo "Starting listener (background)..."
nohup swift "$LISTENER" &>"$LOG" & echo $! > "$PIDFILE"
sleep 0.3
echo "Listener PID: $(cat "$PIDFILE")"
echo "Listener log head:" && sed -n '1,80p' "$LOG" || true

# Wait for the socket to appear (fast-path) for up to SOCKET_WAIT seconds.
# If it doesn't appear, we continue and the CLI will fallback to notifications/file.
SOCKET_WAIT=3
echo "Waiting up to ${SOCKET_WAIT}s for socket $SOCK to appear..."
found_sock=0
for i in $(seq 1 $((SOCKET_WAIT * 10))); do
  if [ -S "$SOCK" ]; then
    found_sock=1
    break
  fi
  sleep 0.1
done
if [ "$found_sock" -eq 1 ]; then
  echo "Socket detected: $SOCK"
else
  echo "Warning: socket $SOCK not present after ${SOCKET_WAIT}s; continuing — CLI will fallback to notifications/file."
fi

# Ensure CLI binary exists; build if missing
if [ ! -x "$CLI" ]; then
  echo "CLI binary not found at $CLI — building Tools/deskpadctl..."
  (cd "$REPO_ROOT/Tools/deskpadctl" && swift build -c release) || {
    echo "Failed to build deskpadctl; aborting smoke test." >&2
    if [ -f "$PIDFILE" ]; then kill "$(cat "$PIDFILE")" 2>/dev/null || true; rm -f "$PIDFILE"; fi
    exit 1
  }
  if [ ! -x "$CLI" ]; then
    echo "Build completed but CLI binary still missing: $CLI" >&2
    if [ -f "$PIDFILE" ]; then kill "$(cat "$PIDFILE")" 2>/dev/null || true; rm -f "$PIDFILE"; fi
    exit 1
  fi
fi

run_and_time() {
  # Accept the command as separate args to preserve quoting/spaces
  local -a cmd=("${@}")
  local t0=$(now)
  local output
  local rc
  # run the command and capture output
  if output=$("${cmd[@]}" 2>&1); then
    rc=0
  else
    rc=$?
  fi
  local t1=$(now)
  local dt=$(awk "BEGIN{print ($t1 - $t0)}")
  printf "cmd: %s\nret: %s\ntime: %.6fs\noutput:\n%s\n---\n" "${cmd[*]}" "$rc" "$dt" "$output"
}

echo "Running sample commands..."
run_and_time "$CLI" create --width 1280 --height 720 --name "IPC Test 1"
run_and_time "$CLI" list
run_and_time "$CLI" create --width 2560 --height 1440 --name "IPC Test 2"
run_and_time "$CLI" list
run_and_time "$CLI" remove 1000
run_and_time "$CLI" list

echo "Listener log tail:" && tail -n 200 "$LOG" || true

echo "Stopping listener..."
if [ -f "$PIDFILE" ]; then kill "$(cat "$PIDFILE")" 2>/dev/null || true; rm -f "$PIDFILE"; fi

echo "Done."
