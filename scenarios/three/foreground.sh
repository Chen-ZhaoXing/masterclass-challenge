#!/bin/bash
echo "Setting up the environment..."
echo "Deploying a private container registry and pre-pulling base images..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done
echo ""
echo "Environment setup complete! Private registry is available at localhost:30500"
echo ""

# Build the bloated image so the participant can see how bad it is
echo "Building the rogue elves' original bloated image so you can see the damage..."
docker build -t localhost:30500/sleigh-telemetry:bloated ~/bloated-app/ 2>/dev/null

echo ""
echo "============================================"
echo "  CURRENT IMAGE SIZE (the rogue elves' mess):"
docker images localhost:30500/sleigh-telemetry:bloated --format "  {{.Repository}}:{{.Tag}}  {{.Size}}"
echo "============================================"
echo ""
echo "Your mission: rewrite the Dockerfile to get this under 250 MB and running as non-root."
echo "Good luck, Security Elf!"
echo ""

cd ~/bloated-app
