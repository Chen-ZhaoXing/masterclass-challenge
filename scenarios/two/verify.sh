#!/bin/bash

# The user is expected to fix the helm chart and be able to template/apply it successfully
# We verify if they can successfully dry-run apply the rendered helm chart to the cluster
# Kyverno will block it if the policies are not satisfied.

# Ensure the background setup has completed before verifying
if [ ! -f /tmp/setup-finished ]; then
    echo "Environment is still being set up. Please wait for the setup to complete before verifying."
    exit 1
fi

# Re-apply policies in case the user accidentally or intentionally deleted them
kubectl apply -f https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-policies/masterclass-policies.yaml > /dev/null 2>&1

cd ~/app-chart || exit 1

# If the template command fails, they have a syntax error
TEMPLATE_OUT=$(helm template release-name . -f values.yaml 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Helm template failed. Please check your syntax."
    exit 1
fi

# Attempt to dry-run apply to cluster to trigger Kyverno validation
echo "$TEMPLATE_OUT" | kubectl apply --dry-run=server -f - > /dev/null 2>&1
if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi
