#!/bin/bash
echo "Installing scenario..."
while [ ! -f /opt/background-finished ]; do
  sleep 1
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
  echo DONE

  helm upgrade --install challenge1 ~/masterclass-fastapi-app -n challenge1

  kubectl wait --for=condition=available deployment challenge1 -n challenge1 --timeout=60s || true

  cd ~/masterclass-fastapi-app
fi
