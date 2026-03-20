#!/bin/bash

# Target the user's terminal
TERMINAL="/dev/pts/0"

# Create a function to send text to the terminal
term_echo() {
    echo -e "$1" > $TERMINAL
}

term_echo "========================================"
term_echo "  North Pole Container Standards Check"
term_echo "========================================"

# ... in your checks ...
if echo "$REGISTRY_CHECK" | grep -q '"latest"'; then
    term_echo "  ✅ Image found in registry."
else
    term_echo "  ❌ Image not found!"
    FAIL=1
fi

# ... at the very end ...
if [ "$FAIL" -eq 0 ]; then
    exit 0
else
    exit 1
fi