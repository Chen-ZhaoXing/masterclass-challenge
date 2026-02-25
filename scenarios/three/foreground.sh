#!/bin/bash
echo "Setting up the environment..."
echo "Deploying a private container registry to the cluster..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done
echo ""
echo "Environment setup complete! Private registry is available at localhost:30500"
echo "You can now begin the challenge."
