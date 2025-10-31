#!/bin/bash

# Script to add DeskPad as a git submodule
# Usage: ./scripts/add-deskpad-submodule.sh <deskpad-repo-url>

set -e

if [ -z "$1" ]; then
    echo "Error: DeskPad repository URL is required"
    echo ""
    echo "Usage: $0 <deskpad-repo-url>"
    echo ""
    echo "Example:"
    echo "  $0 https://github.com/example/DeskPad.git"
    echo ""
    exit 1
fi

DESKPAD_URL="$1"

echo "Adding DeskPad as a submodule..."

# Remove placeholder if it exists
if [ -d "submodules/DeskPad" ]; then
    echo "Removing existing placeholder directory..."
    rm -rf submodules/DeskPad
fi

# Add the submodule
echo "Adding submodule from: $DESKPAD_URL"
git submodule add "$DESKPAD_URL" submodules/DeskPad

# Initialize and update
echo "Initializing and updating submodule..."
git submodule init
git submodule update

# Check status
echo ""
echo "Submodule added successfully!"
echo ""
git submodule status

echo ""
echo "Next steps:"
echo "1. Review the integration guide in Sources/PaperWM/INTEGRATION.md"
echo "2. Copy DisplayControlHook.swift into the DeskPad project"
echo "3. Modify DeskPad to initialize the hook"
echo "4. Build and test the integration"
