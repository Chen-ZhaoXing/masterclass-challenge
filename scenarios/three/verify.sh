#!/bin/bash

# Ensure the background setup has completed before verifying
if [ ! -f /tmp/setup-finished ]; then
    echo "Environment is still being set up. Please wait for the setup to complete before verifying."
    exit 1
fi

FAIL=0

echo "========================================"
echo "  North Pole Container Standards Check"
echo "========================================"
echo ""

# ------------------------------------------------------------------
# CHECK 1: Image must exist in the local registry
# ------------------------------------------------------------------
echo "[1/5] Checking if image is pushed to the local registry..."
REGISTRY_CHECK=$(curl -sf http://localhost:30500/v2/sleigh-telemetry/tags/list 2>/dev/null)
if echo "$REGISTRY_CHECK" | grep -q '"latest"'; then
    echo "  ✅ Image found in registry."
else
    echo "  ❌ Image not found in the local registry."
    FAIL=1
fi

# ------------------------------------------------------------------
# CHECK 2: Image size must be under 250 MB
# ------------------------------------------------------------------
echo ""
echo "[2/5] Checking image size..."
# Pull the latest from registry to ensure we're checking the pushed version
docker pull localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1
IMAGE_SIZE_BYTES=$(docker inspect localhost:30500/sleigh-telemetry:latest --format '{{.Size}}' 2>/dev/null)
if [ -z "$IMAGE_SIZE_BYTES" ]; then
    echo "  ❌ Could not determine image size."
    FAIL=1
else
    IMAGE_SIZE_MB=$((IMAGE_SIZE_BYTES / 1024 / 1024))
    MAX_SIZE_MB=250
    if [ "$IMAGE_SIZE_MB" -lt "$MAX_SIZE_MB" ]; then
        echo "  ✅ Image size is ${IMAGE_SIZE_MB} MB (limit: ${MAX_SIZE_MB} MB)."
    else
        echo "  ❌ Image size is ${IMAGE_SIZE_MB} MB — exceeds the ${MAX_SIZE_MB} MB limit."
        FAIL=1
    fi
fi

# ------------------------------------------------------------------
# CHECK 3: Container must NOT run as root
# ------------------------------------------------------------------
echo ""
echo "[3/5] Checking if container runs as non-root..."
CONTAINER_USER=$(docker inspect localhost:30500/sleigh-telemetry:latest --format '{{.Config.User}}' 2>/dev/null)
if [ -z "$CONTAINER_USER" ] || [ "$CONTAINER_USER" = "root" ] || [ "$CONTAINER_USER" = "0" ]; then
    echo "  ❌ Container runs as root."
    FAIL=1
else
    echo "  ✅ Container runs as user '${CONTAINER_USER}' (non-root)."
fi

# ------------------------------------------------------------------
# CHECK 4: Application must respond on port 8000
# ------------------------------------------------------------------
echo ""
echo "[4/5] Checking if the application starts and responds..."
# Clean up any leftover test containers
docker rm -f verify-test-app > /dev/null 2>&1
docker run --rm -d --name verify-test-app -p 8000:8000 localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1

# Give the app a moment to start
sleep 5

HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✅ Application responded with HTTP 200."
else
    echo "  ❌ Application did not respond correctly."
    FAIL=1
fi

docker rm -f verify-test-app > /dev/null 2>&1

# ------------------------------------------------------------------
# CHECK 5: Dockerfile must use multi-stage build
# ------------------------------------------------------------------
echo ""
echo "[5/5] Checking Dockerfile build strategy..."
FROM_COUNT=$(grep -ci '^FROM ' ~/bloated-app/Dockerfile 2>/dev/null)
if [ "$FROM_COUNT" -ge 2 ]; then
    echo "  ✅ Dockerfile uses a multi-stage build (${FROM_COUNT} FROM instructions found)."
else
    echo "  ❌ Dockerfile does not meet the build strategy requirement."
    FAIL=1
fi

# ------------------------------------------------------------------
# RESULT
# ------------------------------------------------------------------
echo ""
echo "========================================"
if [ "$FAIL" -eq 0 ]; then
    echo "  ✅ ALL CHECKS PASSED"
    echo "  The Sleigh Telemetry image meets North Pole Container Standards!"
    echo "========================================"
    exit 0
else
    echo "  ❌ SOME CHECKS FAILED"
    echo "  Review your Dockerfile and try again."
    echo "========================================"
    exit 1
fi
