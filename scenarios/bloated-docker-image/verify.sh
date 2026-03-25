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
broadcast "[1/8] Checking registry..."
REGISTRY_CHECK=$(curl -sf http://localhost:30500/v2/sleigh-telemetry/tags/list 2>/dev/null)
if echo "$REGISTRY_CHECK" | grep -q '"latest"'; then
    broadcast "  ✅ Image found in registry."
else
    broadcast "  ❌ Image not found in the local registry."
    FAIL=1
fi

# --- CHECK 2: Size ---
broadcast "\n[2/8] Checking image size..."
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
broadcast "\n[3/8] Checking OpenShift SCC non-root compliance..."
CONTAINER_USER=$(docker inspect localhost:30500/sleigh-telemetry:latest --format '{{.Config.User}}' 2>/dev/null)
if [[ "$CONTAINER_USER" =~ ^[1-9][0-9]+:0$ ]] || [ "$CONTAINER_USER" = "1001:0" ]; then
    broadcast "  ✅ Container runs as strictly compliant user '${CONTAINER_USER}'."
else
    broadcast "  ❌ Container runs as '${CONTAINER_USER}'. Must be SCC compliant (e.g. 1001:0)."
    FAIL=1
fi

# --- CHECK 4: Multi-Stage ---
broadcast "\n[4/8] Checking build strategy..."
FROM_COUNT=$(grep -ci '^FROM ' /root/bloated-app/Dockerfile 2>/dev/null)
if [ "$FROM_COUNT" -ge 2 ]; then
    broadcast "  ✅ Multi-stage build detected (${FROM_COUNT} stages)."
else
    broadcast "  ❌ Dockerfile is not using a multi-stage build."
    FAIL=1
fi

# --- CHECK 5: HEALTHCHECK ---
broadcast "\n[5/8] Checking HEALTHCHECK..."
if grep -qi '^HEALTHCHECK' /root/bloated-app/Dockerfile 2>/dev/null; then
    broadcast "  ✅ HEALTHCHECK instruction found."
else
    broadcast "  ❌ Dockerfile is missing a HEALTHCHECK instruction."
    FAIL=1
fi

# --- CHECK 6: Metadata (LABEL) ---
broadcast "\n[6/8] Checking metadata LABELS..."
if grep -qi '^LABEL' /root/bloated-app/Dockerfile 2>/dev/null; then
    broadcast "  ✅ LABEL instruction found."
else
    broadcast "  ❌ Dockerfile is missing a LABEL instruction."
    FAIL=1
fi

# --- CHECK 7: Parameterization (ARG) ---
broadcast "\n[7/8] Checking build parameterization..."
if grep -qi '^ARG' /root/bloated-app/Dockerfile 2>/dev/null; then
    broadcast "  ✅ ARG instruction found."
else
    broadcast "  ❌ Dockerfile is missing an ARG instruction."
    FAIL=1
fi

# --- CHECK 8: Layer Caching ---
broadcast "\n[8/8] Checking layer caching..."
# Ensure requirements.txt is copied before src/
REQ_LINE=$(grep -n 'COPY .*requirements.txt' /root/bloated-app/Dockerfile | head -1 | cut -d: -f1)
SRC_LINE=$(grep -n 'COPY .*src/' /root/bloated-app/Dockerfile | tail -1 | cut -d: -f1)

if [ -n "$REQ_LINE" ] && [ -n "$SRC_LINE" ] && [ "$REQ_LINE" -lt "$SRC_LINE" ]; then
    broadcast "  ✅ Dependency installation cached before source code copy."
else
    broadcast "  ❌ Layer caching failed. Copy requirements.txt before copying src/."
    FAIL=1
fi

# --- FINAL RESULT ---
broadcast "\n============================================================"
if [ "$FAIL" -eq 0 ]; then
    broadcast "============================================================\n"
    broadcast "          🎉 ALL CHECKS PASSED! Here is the flag!\n           "
    broadcast "        NOr3CpaqLxxTQ0W3iGyPHbki3Gf1bJntY9rEryyCE20=        \n"
    broadcast "============================================================\n"
    exit 0
else
    broadcast "  ❌ STANDARDS CHECK FAILED"
    broadcast "  Review the output above and try again."
    broadcast "========================================\n"
    exit 1
fi