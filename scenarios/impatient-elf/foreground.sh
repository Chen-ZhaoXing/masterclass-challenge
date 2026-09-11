#!/bin/bash
echo "Setting up the environment..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done

echo ""

# If setup failed, say so plainly. Otherwise the player sees an unhealthy Pod,
# reads "that is the bug" below, and debugs a database that was never deployed.
# if/else rather than `exit`: this script's output goes to the player's terminal,
# and an early exit must never be able to end their shell.
if [ -f /tmp/impatient-elf-setup-failed ]; then
  echo "✗ The environment did not finish setting up:"
  echo "    $(cat /tmp/impatient-elf-setup-failed)"
  echo ""
  echo "This is a problem with the environment, not part of the challenge."
  echo "Restart the scenario, and tell the facilitator if it happens again."
else
  echo "Environment ready. Deploying the gift-registry, as the release crew left it..."
  kubectl apply -f ~/app.yaml
  kubectl get pods -n workshop

  echo ""
  echo "The gift-registry Pod is expected to be unhealthy right now - that is the bug."
  echo "Investigate namespace 'workshop', find out why, and put the elf back in line."
  echo ""
  echo "✅ You can now begin!"
fi
