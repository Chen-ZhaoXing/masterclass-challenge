#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

# Check the ConfigMap exists
kubectl get configmap weather-config >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ No ConfigMap named 'weather-config' found. The app still can't start!"
    exit 1
fi

# Check the ConfigMap has the required keys
APP_MODE=$(kubectl get configmap weather-config -o jsonpath='{.data.APP_MODE}')
LOG_LEVEL=$(kubectl get configmap weather-config -o jsonpath='{.data.LOG_LEVEL}')

if [ -z "$APP_MODE" ]; then
    broadcast "❌ The ConfigMap exists but is missing the 'APP_MODE' key."
    exit 1
fi

if [ -z "$LOG_LEVEL" ]; then
    broadcast "❌ The ConfigMap exists but is missing the 'LOG_LEVEL' key."
    exit 1
fi

# Check the pod is actually running
POD_STATUS=$(kubectl get pods -l app=weather-api -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    broadcast "❌ The ConfigMap looks good but the pod is not Running yet. Try re-applying the deployment."
    exit 1
fi

broadcast "✅ The Weather API is configured and running! ConfigMap created successfully."

broadcast "============================================================\n"
broadcast "          🎉 ALL CHECKS PASSED! Here is the flag!\n           "
broadcast "        A/U1QvwvmF8pE8alSEyC+lJqaTlQIilCimHCC8hIowA=        \n"
broadcast "============================================================\n"

exit 0
