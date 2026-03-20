#!/bin/bash

# Ensure we are in the right directory
cd /root/bloated-app || { echo "Directory /root/bloated-app not found"; exit 1; }

# 1. Wait for background setup (Crucial for Killercoda)
if [ ! -f /tmp/setup-finished ]; then
    echo "---------------------------------------------------------"
    echo "  ⚠️  Environment is still initializing..."
    echo "  Please wait about 10 seconds and try again."
    echo "---------------------------------------------------------"
    exit 1
fi

FAIL=0

# Helper function to print headers
print_header() {
    echo "========================================"
    echo "  North Pole Container Standards Check"
    echo "========================================"
}

# Capture all output so we can present it cleanly
{
    # CHECK 1: Local Registry
    echo -n "[1/5] Registry Check: "
    REGISTRY_CHECK=$(curl -sf http://localhost:30500/v2/sleigh-telemetry/tags/list 2>/dev/null)
    if echo "$REGISTRY_CHECK" | grep -q '"latest"'; then
        echo "✅ Found"
    else
        echo "❌ Missing (Did you push to :30500?)"
        FAIL=1
    fi

    # CHECK 2: Image Size
    echo -n "[2/5] Size Check (<250MB): "
    docker pull localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1
    IMAGE_SIZE_BYTES=$(docker inspect localhost:30500/sleigh-telemetry:latest --format '{{.Size}}' 2>/dev/null)
    if [ -z "$IMAGE_SIZE_BYTES" ]; then
        echo "❌ Error (Image not found)"
        FAIL=1
    else
        IMAGE_SIZE_MB=$((IMAGE_SIZE_BYTES / 1024 / 1024))
        if [ "$IMAGE_SIZE_MB" -lt 250 ]; then
            echo "✅ Pass (${IMAGE_SIZE_MB}MB)"
        else
            echo "❌ Fail (${IMAGE_SIZE_MB}MB)"
            FAIL=1
        fi
    fi

    # CHECK 3: Non-Root User
    echo -n "[3/5] Security Check (Non-Root): "
    CONTAINER_USER=$(docker inspect localhost:30500/sleigh-telemetry:latest --format '{{.Config.User}}' 2>/dev/null)
    if [ -z "$CONTAINER_USER" ] || [ "$CONTAINER_USER" = "root" ] || [ "$CONTAINER_USER" = "0" ]; then
        echo "❌ Fail (Running as root)"
        FAIL=1
    else
        echo "✅ Pass (User: ${CONTAINER_USER})"
    fi

    # CHECK 4: Port 8000 Response
    echo -n "[4/5] Runtime Check (Port 8000): "
    docker rm -f verify-test-app > /dev/null 2>&1
    docker run --rm -d --name verify-test-app -p 8000:8000 localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1
    
    # Quick retry loop for the app to start
    SUCCESS_HTTP=0
    for i in {1..5}; do
        sleep 2
        HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null)
        if [ "$HTTP_CODE" = "200" ]; then SUCCESS_HTTP=1; break; fi
    done

    if [ "$SUCCESS_HTTP" -eq 1 ]; then
        echo "✅ Pass (HTTP 200)"
    else
        echo "❌ Fail (No response)"
        FAIL=1
    fi
    docker rm -f verify-test-app > /dev/null 2>&1

    # CHECK 5: Multi-Stage Build
    echo -n "[5/5] Strategy Check (Multi-stage): "
    FROM_COUNT=$(grep -ci '^FROM ' /root/bloated-app/Dockerfile 2>/dev/null)
    if [ "$FROM_COUNT" -ge 2 ]; then
        echo "✅ Pass (${FROM_COUNT} stages)"
    else
        echo "❌ Fail (Only ${FROM_COUNT} stage found)"
        FAIL=1
    fi

    echo "========================================"
} > /tmp/verify-results.txt

# --- Final Output Logic ---
print_header
cat /tmp/verify-results.txt

if [ "$FAIL" -eq 0 ]; then
    echo "  🎉 ALL STANDARDS MET!"
    echo "  The sleigh is ready for departure."
    exit 0
else
    echo "  🚩 STANDARDS NOT MET"
    echo "  Please correct the items marked with ❌"
    exit 1
fi