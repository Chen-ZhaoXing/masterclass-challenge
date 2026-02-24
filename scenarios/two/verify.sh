#!/bin/bash

# The user is expected to fix the helm chart and be able to template/apply it successfully
# We verify if they can successfully dry-run apply the rendered helm chart to the cluster
# Kyverno will block it if the policies are not satisfied.

cd /root/app-chart || exit 1

# If the template command fails, they have a syntax error
TEMPLATE_OUT=$(helm template release-name . -f values.yaml 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Helm template failed. Please check your syntax."
    exit 1
fi

# Attempt to dry-run apply to cluster to trigger Kyverno validation
echo "$TEMPLATE_OUT" | kubectl apply --dry-run=server -f - > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # Kyverno admitted the manifests, which means all policies passed!
    exit 0
else
    # Kyverno rejected the manifests due to missing requirements
    exit 1
fi
