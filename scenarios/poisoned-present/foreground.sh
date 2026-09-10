#!/bin/bash
echo "Setting up the environment..."
echo "Deploying a private container registry, installing Trivy, and pre-fetching the vulnerability DB..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done
echo ""

if [ -f /tmp/setup-failed ]; then
  echo "✗ The environment did not finish setting up:"
  echo "    $(cat /tmp/setup-failed)"
  echo ""
  echo "This is a problem with the environment, not part of the challenge."
  echo "Restart the scenario, and tell the facilitator if it happens again."
else
  echo "Environment setup complete! Private registry is available at localhost:30500"
  echo ""

  # A missing vulnerability DB is recoverable by the player, so say how rather
  # than letting the scan below fail with a cryptic error.
  if [ -f /tmp/trivy-db-failed ]; then
    echo "⚠️  The vulnerability database could not be downloaded during setup, so the scan below will fail."
    echo "   Run 'trivy image --download-db-only' to fetch it, then carry on."
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
      trivy image --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update localhost:30500/sleigh-telemetry:poisoned
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

  # No `|| exit`: Killercoda types this script into the player's shell, so an
  # exit here would close their terminal.
  cd ~/sleigh-telemetry
fi
