#!/bin/bash
# arrange-canvas.sh
# Script to arrange windows on the PaperWM-style canvas

set -e

# Default configuration
CANVAS_WIDTH=${CANVAS_WIDTH:-3840}
CANVAS_HEIGHT=${CANVAS_HEIGHT:-1080}
WINDOW_WIDTH=${WINDOW_WIDTH:-1920}
PADDING=${PADDING:-0}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Arrange windows on a PaperWM-style canvas using DeskPad virtual display.

OPTIONS:
    -w, --canvas-width WIDTH    Canvas width in pixels (default: 3840)
    -h, --canvas-height HEIGHT  Canvas height in pixels (default: 1080)
    -W, --window-width WIDTH    Window width in pixels (default: 1920)
    -p, --padding PADDING       Padding between windows (default: 0)
    --help                      Show this help message

EXAMPLES:
    # Create a canvas with default settings
    $0

    # Create a wider canvas
    $0 --canvas-width 5760 --window-width 1920

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--canvas-width)
            CANVAS_WIDTH="$2"
            shift 2
            ;;
        -h|--canvas-height)
            CANVAS_HEIGHT="$2"
            shift 2
            ;;
        -W|--window-width)
            WINDOW_WIDTH="$2"
            shift 2
            ;;
        -p|--padding)
            PADDING="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo "📐 Arranging PaperWM canvas..."
echo "  Canvas: ${CANVAS_WIDTH}x${CANVAS_HEIGHT}"
echo "  Window width: ${WINDOW_WIDTH}"
echo "  Padding: ${PADDING}"

# Calculate number of windows that fit
NUM_WINDOWS=$(( CANVAS_WIDTH / (WINDOW_WIDTH + PADDING) ))
echo "  Max windows: ${NUM_WINDOWS}"

echo "✓ Canvas arrangement planned"
echo ""
echo "To create the virtual display, run:"
echo "  deskpadctl create --width ${CANVAS_WIDTH} --height ${CANVAS_HEIGHT}"
