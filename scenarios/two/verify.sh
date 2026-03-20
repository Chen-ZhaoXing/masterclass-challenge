#!/bin/bash

# --- TERMINAL INJECTION LOGIC ---
# This function sends whatever is passed to it into every active terminal window.
broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

# The user is expected to fix the helm chart and be able to template/apply it successfully
# We verify if they can successfully dry-run apply the rendered helm chart to the cluster
# Kyverno will block it if the policies are not satisfied.

# Ensure the background setup has completed before verifying
if [ ! -f /tmp/setup-finished ]; then
    broadcast "⚠️  Environment is still being set up. Please wait for the setup to complete before verifying."
    exit 1
fi

# Re-apply policies in case the user accidentally or intentionally deleted them
kubectl apply -f https://raw.githubusercontent.com/yequan99/masterclass-challenge-assets/refs/heads/main/kyverno-policies/masterclass-policies.yaml > /dev/null 2>&1

# Wait for Kyverno to register the policies and update webhooks
sleep 5

cd ~/app-chart || exit 1

# If the template command fails, they have a syntax error
TEMPLATE_OUT=$(helm template release-name . -f values.yaml 2>&1)
if [ $? -ne 0 ]; then
    broadcast "❌ [FAIL] Helm template failed. Please check your syntax."
    broadcast "$TEMPLATE_OUT"
    exit 1
fi

# Attempt to dry-run apply to cluster to trigger Kyverno validation
APPLY_OUT=$(echo "$TEMPLATE_OUT" | kubectl apply --dry-run=server -f - 2>&1)
if [ $? -eq 0 ]; then
    broadcast "✅ [PASS] All Kyverno policies passed! Your Helm chart meets North Pole standards."
    exit 0
else
    broadcast "❌ [FAIL] Kyverno rejected your deployment. Here are the policy violations:"
    broadcast ""
    echo "$APPLY_OUT" | grep -i "failed\|error\|violat\|blocked\|not allowed\|required" | while IFS= read -r line; do
        broadcast "  ❌ $line"
    done
    # If grep didn't match anything, show the full output
    if ! echo "$APPLY_OUT" | grep -qi "failed\|error\|violat\|blocked\|not allowed\|required"; then
        broadcast "$APPLY_OUT"
    fi
    exit 1
fi
