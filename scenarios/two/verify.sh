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

# Wait for Kyverno to register the policies and update webhooks
sleep 5

cd ~/app-chart || exit 1

# If the template command fails, they have a syntax error
TEMPLATE_OUT=$(helm template release-name . -f values.yaml 2>&1)
if [ $? -ne 0 ]; then
    echo "Helm template failed. Please check your syntax."
    echo "$TEMPLATE_OUT"
    exit 1
fi

# Attempt to dry-run apply to cluster to trigger Kyverno validation
APPLY_OUT=$(echo "$TEMPLATE_OUT" | kubectl apply --dry-run=server -f - 2>&1)
if [ $? -eq 0 ]; then
    echo "All Kyverno policies passed! Your Helm chart meets North Pole standards."
    exit 0
else
    echo "Kyverno rejected your deployment. Here are the policy violations:"
    echo ""
    echo "$APPLY_OUT" | grep -i "failed\|error\|violat\|blocked\|not allowed\|required" | while IFS= read -r line; do
        echo "  ❌ $line"
    done
    # If grep didn't match anything, show the full output
    if ! echo "$APPLY_OUT" | grep -qi "failed\|error\|violat\|blocked\|not allowed\|required"; then
        echo "$APPLY_OUT"
    fi
    exit 1
fi
