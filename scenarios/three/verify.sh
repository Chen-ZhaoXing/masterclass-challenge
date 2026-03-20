#!/bin/bash

# 1. Path Check: Ensure script is running in the right directory
cd /root/bloated-app || exit 1

# 2. Check for setup
if [ ! -f /tmp/setup-finished ]; then
    echo "❌ Environment is still being set up. Please wait 10 seconds and try again."
    exit 1
fi

FAIL=0
OUTPUT=""

# Helper function to capture output for the final display
log() {
    OUTPUT="$OUTPUT$1\n"
    echo -e "$1"
}

log "========================================"
log "  North Pole Container Standards Check"
log "========================================"

# --- CHECK 1: Registry ---
REGISTRY_CHECK=$(curl -sf http://localhost:30500/v2/sleigh-telemetry/tags/list 2>/dev/null)
if echo "$REGISTRY_CHECK" | grep -q '"latest"'; then
    log "  ✅ Image found in registry."
else
    log "  ❌ Image not found in the local registry. Did you run 'docker push'?"
    FAIL=1
fi

# ... (rest of your checks) ...

if [ "$FAIL" -eq 0 ]; then
    # Killercoda usually shows a success toast, 
    # but the logs won't stay on screen unless you exit 1.
    # To show logs on success, you'd actually have to fail, 
    # but that's confusing. Keep exit 0 for a green checkmark.
    exit 0
else
    exit 1
fi