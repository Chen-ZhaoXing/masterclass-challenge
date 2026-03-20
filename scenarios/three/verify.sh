#!/bin/bash

# --- TERMINAL INJECTION LOGIC ---
# This function sends whatever is passed to it into every active terminal window.
broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

# --- 1. PRE-CHECK ---
if [ ! -f /tmp/setup-finished ]; then
    broadcast "\n⚠️  Environment is still being set up. Please wait..."
    exit 1
fi

FAIL=0

# --- START OUTPUT ---
broadcast "\n========================================"
broadcast "  North Pole Container Standards Check"
broadcast "========================================"

# --- CHECK 1: Registry ---
broadcast "[1/5] Checking registry..."
REGISTRY_CHECK=$(curl -sf http://localhost:30500/v2/sleigh-telemetry/tags/list 2>/dev/null)
if echo "$REGISTRY_CHECK" | grep -q '"latest"'; then
    broadcast "  ✅ Image found in registry."
else
    broadcast "  ❌ Image not found in the local registry."
    FAIL=1
fi

# --- CHECK 2: Size ---
broadcast "\n[2/5] Checking image size..."
docker pull localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1
IMAGE_SIZE_BYTES=$(docker inspect localhost:30500/sleigh-telemetry:latest --format '{{.Size}}' 2>/dev/null)
if [ -z "$IMAGE_SIZE_BYTES" ]; then
    broadcast "  ❌ Could not determine image size."
    FAIL=1
else
    IMAGE_SIZE_MB=$((IMAGE_SIZE_BYTES / 1024 / 1024))
    if [ "$IMAGE_SIZE_MB" -lt 250 ]; then
        broadcast "  ✅ Image size is ${IMAGE_SIZE_MB} MB (limit: 250 MB)."
    else
        broadcast "  ❌ Image size is ${IMAGE_SIZE_MB} MB — too large!"
        FAIL=1
    fi
fi

# --- CHECK 3: Non-Root ---
broadcast "\n[3/5] Checking non-root user..."
CONTAINER_USER=$(docker inspect localhost:30500/sleigh-telemetry:latest --format '{{.Config.User}}' 2>/dev/null)
if [ -z "$CONTAINER_USER" ] || [ "$CONTAINER_USER" = "root" ] || [ "$CONTAINER_USER" = "0" ]; then
    broadcast "  ❌ Container runs as root."
    FAIL=1
else
    broadcast "  ✅ Container runs as user '${CONTAINER_USER}'."
fi

# --- CHECK 4: Runtime ---
broadcast "\n[4/5] Checking application response..."
docker rm -f verify-test-app > /dev/null 2>&1
docker run --rm -d --name verify-test-app -p 8000:8000 localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1
sleep 5
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    broadcast "  ✅ Application responded with HTTP 200."
else
    broadcast "  ❌ Application did not respond (Port 8000)."
    FAIL=1
fi
docker rm -f verify-test-app > /dev/null 2>&1

# --- CHECK 5: Multi-Stage ---
broadcast "\n[5/5] Checking build strategy..."
FROM_COUNT=$(grep -ci '^FROM ' /root/bloated-app/Dockerfile 2>/dev/null)
if [ "$FROM_COUNT" -ge 2 ]; then
    broadcast "  ✅ Multi-stage build detected (${FROM_COUNT} stages)."
else
    broadcast "  ❌ Dockerfile is not using a multi-stage build."
    FAIL=1
fi

# --- FINAL RESULT ---
broadcast "\n========================================"
if [ "$FAIL" -eq 0 ]; then
    broadcast "  🎉 ALL CHECKS PASSED!"
    broadcast "========================================\n"
    exit 0
else
    broadcast "  ❌ STANDARDS CHECK FAILED"
    broadcast "  Review the output above and try again."
    broadcast "========================================\n"
    exit 1
fi