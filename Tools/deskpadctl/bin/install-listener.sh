#!/bin/sh
# install-listener.sh - Manage DeskPad listener service
# POSIX-compliant shell script for installing and managing the DeskPad listener as a launchd service

set -e

# Configuration
LABEL="com.deskpad.displaycontrol"
PLIST_TEMPLATE="$(cd "$(dirname "$0")/../launchd" && pwd)/${LABEL}.plist.template"
LAUNCHAGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_DEST="${LAUNCHAGENTS_DIR}/${LABEL}.plist"

# Default paths
SOCKET_PATH="/tmp/deskpad.sock"
LOG_PATH="/tmp/deskpad-listener.log"
HEALTH_PATH="/tmp/deskpad-listener.health"
STDOUT_LOG="${LOG_PATH}.stdout"
STDERR_LOG="${LOG_PATH}.stderr"

# Detect repository root and listener binary
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LISTENER_SWIFT="${REPO_ROOT}/test-listener.swift"

# Check for compiled listener binary
if [ -f "${REPO_ROOT}/test-listener" ]; then
    LISTENER_BINARY="${REPO_ROOT}/test-listener"
else
    # Fall back to running swift directly (slower but works)
    LISTENER_BINARY="/usr/bin/swift"
    LISTENER_ARGS="${LISTENER_SWIFT}"
fi

usage() {
    cat << 'EOF'
Usage: install-listener.sh <command>

Commands:
  install     Install and start the DeskPad listener service
  start       Start the listener service
  stop        Stop the listener service
  status      Show listener service status
  uninstall   Stop and remove the listener service

Environment Variables:
  DESKPAD_SOCKET_PATH   Socket path (default: /tmp/deskpad.sock)
  DESKPAD_LOG_PATH      Log file path (default: /tmp/deskpad-listener.log)
  DESKPAD_HEALTH_PATH   Health file path (default: /tmp/deskpad-listener.health)

Examples:
  install-listener.sh install
  install-listener.sh status
  install-listener.sh uninstall
EOF
}

check_prerequisites() {
    # Check for launchctl
    if ! command -v launchctl >/dev/null 2>&1; then
        echo "Error: launchctl not found. This script requires macOS with launchd." >&2
        exit 1
    fi
    
    # Check for Swift listener source
    if [ ! -f "${LISTENER_SWIFT}" ]; then
        echo "Error: Listener source not found at ${LISTENER_SWIFT}" >&2
        exit 1
    fi
    
    # Check for plist template
    if [ ! -f "${PLIST_TEMPLATE}" ]; then
        echo "Error: Plist template not found at ${PLIST_TEMPLATE}" >&2
        exit 1
    fi
}

clean_stale_files() {
    echo "Cleaning stale files..."
    
    # Remove stale socket
    if [ -e "${SOCKET_PATH}" ]; then
        echo "  Removing stale socket: ${SOCKET_PATH}"
        rm -f "${SOCKET_PATH}"
    fi
    
    # Remove stale health file
    if [ -f "${HEALTH_PATH}" ]; then
        echo "  Removing stale health file: ${HEALTH_PATH}"
        rm -f "${HEALTH_PATH}"
    fi
}

install_service() {
    echo "Installing DeskPad listener service..."
    check_prerequisites
    
    # Create LaunchAgents directory if it doesn't exist
    if [ ! -d "${LAUNCHAGENTS_DIR}" ]; then
        echo "Creating ${LAUNCHAGENTS_DIR}..."
        mkdir -p "${LAUNCHAGENTS_DIR}"
    fi
    
    # Clean stale files before installation
    clean_stale_files
    
    # Generate plist from template
    echo "Generating plist at ${PLIST_DEST}..."
    
    # For compiled binary
    if [ -f "${REPO_ROOT}/test-listener" ]; then
        sed -e "s|LISTENER_BINARY_PATH|${LISTENER_BINARY}|g" \
            -e "s|SOCKET_PATH|${SOCKET_PATH}|g" \
            -e "s|LOG_PATH|${LOG_PATH}|g" \
            -e "s|HEALTH_PATH|${HEALTH_PATH}|g" \
            -e "s|STDOUT_LOG_PATH|${STDOUT_LOG}|g" \
            -e "s|STDERR_LOG_PATH|${STDERR_LOG}|g" \
            -e "s|WORKING_DIRECTORY|${REPO_ROOT}|g" \
            "${PLIST_TEMPLATE}" > "${PLIST_DEST}"
    else
        # For swift interpreter, we need to construct the full command
        # This is trickier in a plist - we'll use swift as the program and pass the script as an argument
        TMP_PLIST="/tmp/deskpad-plist-$$.xml"
        sed -e "s|LISTENER_BINARY_PATH|${LISTENER_BINARY}|g" \
            -e "s|SOCKET_PATH|${SOCKET_PATH}|g" \
            -e "s|LOG_PATH|${LOG_PATH}|g" \
            -e "s|HEALTH_PATH|${HEALTH_PATH}|g" \
            -e "s|STDOUT_LOG_PATH|${STDOUT_LOG}|g" \
            -e "s|STDERR_LOG_PATH|${STDERR_LOG}|g" \
            -e "s|WORKING_DIRECTORY|${REPO_ROOT}|g" \
            "${PLIST_TEMPLATE}" > "${TMP_PLIST}"
        
        # Add the swift script as an additional argument
        # Use sed to insert the script path after the binary path in ProgramArguments
        sed -i.bak '/<string>\/usr\/bin\/swift<\/string>/a\
        <string>'"${LISTENER_SWIFT}"'</string>' "${TMP_PLIST}"
        
        mv "${TMP_PLIST}" "${PLIST_DEST}"
        rm -f "${TMP_PLIST}.bak"
    fi
    
    # Set proper permissions
    chmod 644 "${PLIST_DEST}"
    
    # Bootstrap the service (loads and starts it)
    echo "Bootstrapping service with launchctl..."
    if launchctl bootstrap "gui/$(id -u)" "${PLIST_DEST}" 2>/dev/null; then
        echo "✓ Service installed and started successfully"
    else
        # Service might already be loaded, try to reload it
        echo "Service already loaded, attempting to reload..."
        launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
        sleep 1
        launchctl bootstrap "gui/$(id -u)" "${PLIST_DEST}"
        echo "✓ Service reloaded successfully"
    fi
    
    # Wait a moment for service to start
    sleep 2
    
    echo ""
    echo "DeskPad listener installed!"
    echo "  Socket path:  ${SOCKET_PATH}"
    echo "  Log path:     ${LOG_PATH}"
    echo "  Health path:  ${HEALTH_PATH}"
    echo "  Stdout log:   ${STDOUT_LOG}"
    echo "  Stderr log:   ${STDERR_LOG}"
    echo ""
    echo "Check status with: $0 status"
}

start_service() {
    echo "Starting DeskPad listener service..."
    check_prerequisites
    
    if [ ! -f "${PLIST_DEST}" ]; then
        echo "Error: Service not installed. Run '$0 install' first." >&2
        exit 1
    fi
    
    # Clean stale files before starting
    clean_stale_files
    
    # Try to start/enable the service
    if launchctl enable "gui/$(id -u)/${LABEL}" 2>/dev/null; then
        echo "✓ Service enabled"
    fi
    
    if launchctl kickstart "gui/$(id -u)/${LABEL}" 2>/dev/null; then
        echo "✓ Service started successfully"
    else
        echo "Note: Service may already be running"
    fi
    
    sleep 1
    show_status
}

stop_service() {
    echo "Stopping DeskPad listener service..."
    
    if launchctl kill SIGTERM "gui/$(id -u)/${LABEL}" 2>/dev/null; then
        echo "✓ Service stopped successfully"
    else
        echo "Note: Service may not be running"
    fi
    
    sleep 1
    show_status
}

show_status() {
    echo "DeskPad listener service status:"
    echo ""
    
    # Check if plist exists
    if [ -f "${PLIST_DEST}" ]; then
        echo "✓ Service plist installed at ${PLIST_DEST}"
    else
        echo "✗ Service plist not found (not installed)"
    fi
    
    # Check launchctl status
    if launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1; then
        echo "✓ Service loaded in launchd"
        
        # Get PID if available
        SERVICE_INFO="$(launchctl print "gui/$(id -u)/${LABEL}" 2>/dev/null || true)"
        PID="$(echo "${SERVICE_INFO}" | grep -o 'pid = [0-9]*' | sed 's/pid = //' || true)"
        if [ -n "${PID}" ]; then
            echo "  PID: ${PID}"
        fi
        
        STATE="$(echo "${SERVICE_INFO}" | grep -o 'state = [a-z]*' | sed 's/state = //' || true)"
        if [ -n "${STATE}" ]; then
            echo "  State: ${STATE}"
        fi
    else
        echo "✗ Service not loaded in launchd"
    fi
    
    # Check socket
    if [ -S "${SOCKET_PATH}" ]; then
        echo "✓ Socket exists at ${SOCKET_PATH}"
        # shellcheck disable=SC2012
        ls -l "${SOCKET_PATH}" | awk '{print "  Permissions: " $1 " Owner: " $3}'
    else
        echo "✗ Socket not found at ${SOCKET_PATH}"
    fi
    
    # Check health file
    if [ -f "${HEALTH_PATH}" ]; then
        echo "✓ Health file exists at ${HEALTH_PATH}"
        echo "  Contents:"
        sed 's/^/    /' "${HEALTH_PATH}"
    else
        echo "✗ Health file not found at ${HEALTH_PATH}"
    fi
    
    # Check log file
    if [ -f "${LOG_PATH}" ]; then
        echo "✓ Log file exists at ${LOG_PATH}"
        echo "  Last 5 lines:"
        tail -5 "${LOG_PATH}" | sed 's/^/    /'
    else
        echo "✗ Log file not found at ${LOG_PATH}"
    fi
}

uninstall_service() {
    echo "Uninstalling DeskPad listener service..."
    
    # Stop and unload the service
    if launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null; then
        echo "✓ Service stopped and unloaded"
    else
        echo "Note: Service was not running"
    fi
    
    # Remove plist
    if [ -f "${PLIST_DEST}" ]; then
        rm -f "${PLIST_DEST}"
        echo "✓ Removed plist at ${PLIST_DEST}"
    fi
    
    # Clean up runtime files
    clean_stale_files
    
    echo "✓ DeskPad listener service uninstalled"
}

# Main command dispatcher
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

case "$1" in
    install)
        install_service
        ;;
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    status)
        show_status
        ;;
    uninstall)
        uninstall_service
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Error: Unknown command '$1'" >&2
        echo "" >&2
        usage
        exit 1
        ;;
esac
