#!/bin/bash
echo "Setting up the environment..."
while [ ! -f /tmp/setup-finished ]; do
  sleep 2
  echo -n "."
done

echo ""
echo "Environment ready. Deploying the gift-registry, as the release crew left it..."
kubectl apply -f ~/app.yaml
kubectl get pods -n workshop

echo ""
echo "The gift-registry Pod is expected to be unhealthy right now - that is the bug."
echo "Investigate namespace 'workshop', find out why, and put the elf back in line."
echo ""
echo "✅ You can now begin!"
