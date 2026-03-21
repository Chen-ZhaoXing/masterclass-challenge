#!/bin/bash
echo "Setting up the environment..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done
echo ""
echo "You can now begin!"