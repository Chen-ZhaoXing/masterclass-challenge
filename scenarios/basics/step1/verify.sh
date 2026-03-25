#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

# Check if the deployment exists and is running
kubectl get deployment gift-tracker >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The 'gift-tracker' deployment does not exist yet. Did you fix all the errors and run kubectl apply?"
    exit 1
else
    broadcast "✅ The 'gift-tracker' deployment exists!"
fi

# Verify it has available replicas (meaning the pod actually started)
AVAILABLE=$(kubectl get deployment gift-tracker -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$AVAILABLE" ] || [ "$AVAILABLE" -lt 1 ]; then
    broadcast "⏳ The deployment exists but no pods are available yet. Check for remaining errors with: kubectl describe deployment gift-tracker"
    exit 1
else
    broadcast "✅ The 'gift-tracker' deployment is running with $AVAILABLE available replica(s)!"
fi

exit 0
