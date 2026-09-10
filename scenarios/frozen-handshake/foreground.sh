#!/bin/bash
echo "Preparing TLS challenge environment..."
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
  echo "Environment ready. Deploying the broken client chart..."
  helm upgrade --install challenge4 ~/tls-client-chart -n challenge4 >/dev/null 2>&1 || true
  kubectl get pods -n challenge4

  echo ""
  echo "The client deployment is intentionally broken right now (missing CA cert mount)."
  echo "Fix ~/tls-client-chart/templates/deployment.yaml and rerun verification."

  cd ~/tls-client-chart || exit 1
fi
