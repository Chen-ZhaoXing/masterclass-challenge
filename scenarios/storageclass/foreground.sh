#!/bin/bash
echo "Setting up the environment..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done

if [ -f /tmp/setup-failed ]; then
  echo ""
  echo "✗ The environment did not finish setting up:"
  echo "    $(cat /tmp/setup-failed)"
  echo ""
  echo "This is a problem with the environment, not part of the challenge."
  echo "Restart the scenario, and tell the facilitator if it happens again."
else
  echo "✅ You can now begin!"
fi
