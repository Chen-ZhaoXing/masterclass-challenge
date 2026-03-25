#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

# Check if the deployment exists
kubectl get deployment naughty-nice-api >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The 'naughty-nice-api' deployment does not exist. Did you apply the manifest?"
    exit 1
fi

# Check the command is fixed
CMD=$(kubectl get deployment naughty-nice-api -o jsonpath='{.spec.template.spec.containers[0].command[0]}' 2>/dev/null)
if [ "$CMD" = "pythn" ]; then
    broadcast "❌ The container command is still 'pythn'. Check your spelling! Run: kubectl logs <pod-name>"
    exit 1
else
    broadcast "✅ Command looks correct: $CMD"
fi

# Check for running pods
AVAILABLE=$(kubectl get deployment naughty-nice-api -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$AVAILABLE" ] || [ "$AVAILABLE" -lt 1 ]; then
    broadcast "⏳ The deployment exists but pods aren't running yet. Run: kubectl get pods"
    exit 1
else
    broadcast "✅ The 'naughty-nice-api' pod is running!"
fi

broadcast "✅ The Crash Loop has been broken!"
exit 0
