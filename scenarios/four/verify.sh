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
    echo "  ✅ Image 'sleigh-telemetry:latest' found in registry."
else
    echo "  ❌ Image 'sleigh-telemetry:latest' NOT found in the local registry."
    echo "     Hint: Build and push your image:"
    echo "       docker build -t localhost:30500/sleigh-telemetry:latest ~/bloated-app/"
    echo "       docker push localhost:30500/sleigh-telemetry:latest"
    FAIL=1
fi

# ------------------------------------------------------------------
# CHECK 2: Image size must be under 150 MB
# ------------------------------------------------------------------
echo ""
echo "[2/5] Checking image size..."
# Pull the latest from registry to ensure we're checking the pushed version
docker pull localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1
IMAGE_SIZE_BYTES=$(docker inspect localhost:30500/sleigh-telemetry:latest --format '{{.Size}}' 2>/dev/null)
if [ -z "$IMAGE_SIZE_BYTES" ]; then
    echo "  ❌ Could not determine image size. Is the image built locally?"
    echo "     Hint: Run 'docker images localhost:30500/sleigh-telemetry:latest' to check."
    FAIL=1
else
    IMAGE_SIZE_MB=$((IMAGE_SIZE_BYTES / 1024 / 1024))
    MAX_SIZE_MB=150
    if [ "$IMAGE_SIZE_MB" -lt "$MAX_SIZE_MB" ]; then
        echo "  ✅ Image size is ${IMAGE_SIZE_MB} MB (limit: ${MAX_SIZE_MB} MB)."
    else
        echo "  ❌ Image size is ${IMAGE_SIZE_MB} MB — exceeds the ${MAX_SIZE_MB} MB limit!"
        echo "     Hint: Use a multi-stage build with a slim base image (e.g., python:3.13-slim)."
        echo "     Hint: Make sure build tools and pip cache are NOT in the final image."
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
    echo "  ❌ Container runs as root (User='${CONTAINER_USER:-<not set>}')."
    echo "     Hint: Add a USER directive in your Dockerfile to run as a non-root user."
    echo "     Example:"
    echo "       RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser"
    echo "       USER appuser"
    FAIL=1
else
    echo "  ✅ Container runs as user '${CONTAINER_USER}' (non-root)."
fi

# ------------------------------------------------------------------
# CHECK 4: Application must respond on port 8000
# ------------------------------------------------------------------
echo ""
echo "[4/5] Checking if the application starts and responds on port 8000..."
# Clean up any leftover test containers
docker rm -f verify-test-app > /dev/null 2>&1
docker run --rm -d --name verify-test-app -p 8000:8000 localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1

# Give the app a moment to start
sleep 5

HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✅ Application responded with HTTP 200 on port 8000."
else
    echo "  ❌ Application did NOT respond on port 8000 (HTTP code: '${HTTP_CODE:-none}')."
    echo "     Hint: Make sure the FastAPI app starts correctly."
    echo "     Check: docker logs verify-test-app"
    FAIL=1
fi

docker rm -f verify-test-app > /dev/null 2>&1

# ------------------------------------------------------------------
# CHECK 5: Dockerfile must use multi-stage build
# ------------------------------------------------------------------
echo ""
echo "[5/5] Checking if Dockerfile uses a multi-stage build..."
FROM_COUNT=$(grep -ci '^FROM ' ~/bloated-app/Dockerfile 2>/dev/null)
if [ "$FROM_COUNT" -ge 2 ]; then
    echo "  ✅ Dockerfile uses a multi-stage build (${FROM_COUNT} FROM instructions found)."
else
    echo "  ❌ Dockerfile does NOT use a multi-stage build (only ${FROM_COUNT:-0} FROM instruction found)."
    echo "     Hint: Use one FROM for the build stage (install deps) and another FROM for the runtime stage."
    echo "     Example:"
    echo "       FROM python:3.13 AS builder"
    echo "       ...install dependencies..."
    echo "       FROM python:3.13-slim"
    echo "       ...copy only what's needed from builder..."
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
    echo "  Review the hints above and try again."
    echo "========================================"
    exit 1
fi
