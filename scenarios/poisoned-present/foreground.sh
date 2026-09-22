#!/bin/bash
echo "Setting up the environment..."
echo "Deploying a private container registry, installing Trivy, and pre-fetching the vulnerability DB..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done
echo ""
echo "Environment setup complete! Private registry is available at localhost:30500"
echo ""

# The vulnerability DB is fetched once during setup and every scan afterwards runs
# with --skip-db-update, so a failed fetch breaks the scan below *and* every Check
# the participant clicks. background.sh leaves a marker when that happens; retry
# here, while there is still a terminal-free moment, rather than letting the
# scenario open on a database error that looks like a broken challenge.
if [ -f /tmp/trivy-db-failed ]; then
    echo "The vulnerability database did not download during setup. Retrying..."
    if trivy image --download-db-only > /tmp/trivy-db-retry.log 2>&1; then
        rm -f /tmp/trivy-db-failed
        echo "Vulnerability database downloaded."
    else
        echo "⚠️  Still could not download the vulnerability database."
        echo "   This is an environment problem, not something you caused."
        echo "   Retry by hand with: trivy image --download-db-only"
    fi
    echo ""
fi

# Build the poisoned image so the participant can see exactly what they're up against.
# Build output is kept (not sent to /dev/null) so a build failure is visible as a
# build failure, rather than silently producing an empty scan below.
echo "Building the rogue elves' current image so you can see the damage..."
if docker build -t localhost:30500/sleigh-telemetry:poisoned ~/sleigh-telemetry/ > /tmp/poisoned-build.log 2>&1; then
    echo ""
    echo "============================================"
    echo "  TRIVY SCAN — CURRENT IMAGE (the rogue elves' mess):"
    echo "============================================"
    # A failed scan must explain itself. Without this the participant sees a bare
    # FATAL from Trivy directly under a banner promising a vulnerability table,
    # and reasonably concludes the image, not the database, is at fault.
    if ! trivy image --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update \
            localhost:30500/sleigh-telemetry:poisoned 2>/tmp/poisoned-scan.log; then
        echo ""
        echo "⚠️  The scan could not run. Trivy reported:"
        tail -5 /tmp/poisoned-scan.log | sed 's/^/     /'
        echo ""
        echo "   The image itself built fine - this is the scanner, not your code."
        echo "   Recover with: trivy image --download-db-only"
        echo "   (full log: /tmp/poisoned-scan.log)"
    fi
    echo "============================================"
else
    echo ""
    echo "⚠️  The starting image failed to build. Last lines of the build log:"
    tail -20 /tmp/poisoned-build.log
    echo "   (full log: /tmp/poisoned-build.log)"
fi

echo ""
echo "Your mission: patch this until the scan comes back clean, then push it as :latest."
echo "Good luck, Security Elf!"
echo ""

cd ~/sleigh-telemetry || exit 1
