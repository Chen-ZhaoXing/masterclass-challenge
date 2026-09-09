#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

if [ ! -f /tmp/setup-finished ]; then
    broadcast "\n⚠️  Environment is still being set up. Please wait..."
    exit 1
fi

# The vulnerability DB is fetched once during setup; verify.sh scans offline with
# --skip-db-update. If that fetch failed, say so plainly rather than failing the
# student for a broken environment.
if [ -f /tmp/trivy-db-failed ]; then
    broadcast "\n⚠️  The vulnerability database could not be downloaded during setup."
    broadcast "   Run 'trivy image --download-db-only' in the terminal, then click Check again."
    exit 1
fi

FAIL=0

broadcast "\n========================================"
broadcast "  North Pole Supply Chain Check"
broadcast "========================================"

# --- CHECK 1: image exists in the registry ---
broadcast "[1/3] Checking registry..."
REGISTRY_CHECK=$(curl -sf http://localhost:30500/v2/sleigh-telemetry/tags/list 2>/dev/null)
if echo "$REGISTRY_CHECK" | grep -q '"latest"'; then
    broadcast "  ✅ Image found in registry."
else
    broadcast "  ❌ No image tagged 'latest' found in the local registry."
    broadcast "========================================\n"
    exit 1
fi

docker pull localhost:30500/sleigh-telemetry:latest > /dev/null 2>&1

# --- CHECK 2: the service still runs and responds ---
broadcast "\n[2/3] Checking the service still runs..."
docker rm -f sleigh-verify > /dev/null 2>&1

# No --rm: a container that crashes on startup must survive long enough for us to
# read its logs below. Cleanup is handled explicitly at the end of this check.
RUN_ERR=$(docker run -d --name sleigh-verify -p 18000:8000 localhost:30500/sleigh-telemetry:latest 2>&1 >/dev/null)
RUN_EXIT=$?

if [ "$RUN_EXIT" -ne 0 ]; then
    # The image could not even be started. Reporting this as "/health did not
    # respond" would send the student hunting for an application bug that
    # isn't there, so say what actually happened.
    broadcast "  ❌ The image would not start at all. Docker said:"
    broadcast "$(echo "$RUN_ERR" | head -3 | awk '{print "       "$0}')"
    FAIL=1
else
    # Poll rather than sleep for a fixed period: uvicorn cold-start on a loaded
    # Killercoda VM can take several seconds, and a fixed wait would fail a
    # correct solution for timing reasons alone.
    HEALTH_OK=0
    for _ in $(seq 1 15); do
        HEALTH_RESPONSE=$(curl -sf --max-time 3 http://localhost:18000/health 2>/dev/null)
        if echo "$HEALTH_RESPONSE" | grep -q '"healthy":[[:space:]]*true'; then
            HEALTH_OK=1
            break
        fi
        sleep 1
    done

    if [ "$HEALTH_OK" -eq 1 ]; then
        broadcast "  ✅ Service responds correctly on /health."
    else
        broadcast "  ❌ Service did not respond on /health - did the fix break the app?"
        CONTAINER_LOGS=$(docker logs sleigh-verify 2>&1 | tail -8)
        if [ -n "$CONTAINER_LOGS" ]; then
            broadcast "     Last output from the container:"
            broadcast "$(echo "$CONTAINER_LOGS" | awk '{print "       "$0}')"
        fi
        FAIL=1
    fi
fi
docker rm -f sleigh-verify > /dev/null 2>&1

# --- CHECK 3: Trivy scan is clean ---
broadcast "\n[3/3] Running Trivy vulnerability scan..."
TRIVY_OUTPUT=$(trivy image --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update --exit-code 1 --quiet localhost:30500/sleigh-telemetry:latest 2>&1)
TRIVY_EXIT=$?
if [ "$TRIVY_EXIT" -eq 0 ]; then
    broadcast "  ✅ No fixable HIGH/CRITICAL vulnerabilities found."
else
    broadcast "  ❌ Fixable HIGH/CRITICAL vulnerabilities remain:"
    broadcast "$(echo "$TRIVY_OUTPUT" | grep -E 'CVE-' | awk '{print "    - "$0}' | head -15)"
    FAIL=1
fi

broadcast "\n============================================================"
if [ "$FAIL" -eq 0 ]; then
    broadcast "  ✅ SUPPLY CHAIN CHECK PASSED"
    broadcast "  📸 Screenshot this message and submit it for your CTFd points."
    broadcast "========================================\n"
    exit 0
else
    broadcast "  ❌ SUPPLY CHAIN CHECK FAILED"
    broadcast "  Review the output above and try again."
    broadcast "========================================\n"
    exit 1
fi
