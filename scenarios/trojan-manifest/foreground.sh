#!/bin/bash
echo "Setting up the environment..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done

# background.sh records a Kyverno install failure here; without this check the
# player is told to begin with no policy engine running.
if [ -f /tmp/kyverno-setup-failed ]; then
  echo ""
  echo "✗ The environment did not finish setting up:"
  echo "    $(cat /tmp/kyverno-setup-failed)"
  echo ""
  echo "This is a problem with the environment, not part of the challenge."
  echo "Restart the scenario, and tell the facilitator if it happens again."
else
  echo "✅ You can now begin!"
fi
