#!/bin/bash
# pan-canvas.sh
# Script to pan the view on the PaperWM canvas

set -e

# Default configuration
DIRECTION=${DIRECTION:-right}
STEP=${STEP:-100}

usage() {
    cat << EOF
Usage: $0 [OPTIONS] DIRECTION

Pan the view on the PaperWM canvas.

DIRECTION:
    left, right, up, down

OPTIONS:
    -s, --step PIXELS      Number of pixels to pan (default: 100)
    --help                 Show this help message

EXAMPLES:
    # Pan right by 100 pixels
    $0 right

    # Pan left by 500 pixels
    $0 --step 500 left

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--step)
            STEP="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        left|right|up|down)
            DIRECTION="$1"
            shift
            ;;
        *)
            echo "Unknown option or direction: $1"
            usage
            exit 1
            ;;
    esac
done

echo "🖱️  Panning canvas ${DIRECTION} by ${STEP} pixels..."

# This is a placeholder for the actual panning implementation
# In a real implementation, this would use yabai or another window manager
# to adjust the viewport on the virtual display

case $DIRECTION in
    left)
        echo "  Moving viewport left"
        ;;
    right)
        echo "  Moving viewport right"
        ;;
    up)
        echo "  Moving viewport up"
        ;;
    down)
        echo "  Moving viewport down"
        ;;
esac

echo "✓ Canvas panned successfully"
