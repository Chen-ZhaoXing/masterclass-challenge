#!/bin/bash
echo "Setting up the environment..."
echo "Waiting for Kyverno cluster policies to be installed and ready in the background..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done
echo ""
echo "Environment setup complete! Kyverno is now enforcing best practices."
echo "You can now begin the challenge."
