#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

# Check that a Service named gift-dashboard exists
kubectl get service gift-dashboard >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ No Service named 'gift-dashboard' found. The deployment is still invisible!"
    exit 1
fi

# Check the Service targets the correct selector
SVC_SELECTOR=$(kubectl get service gift-dashboard -o jsonpath='{.spec.selector.app}')
if [ "$SVC_SELECTOR" != "gift-dashboard" ]; then
    broadcast "❌ The Service exists but its selector doesn't match the deployment's pod labels."
    exit 1
fi

# Check the Service exposes port 80
SVC_PORT=$(kubectl get service gift-dashboard -o jsonpath='{.spec.ports[0].port}')
if [ "$SVC_PORT" != "80" ]; then
    broadcast "❌ The Service exists but it's not exposing port 80."
    exit 1
fi

# Verify connectivity by resolving the Service DNS
kubectl run dns-test --rm -i --restart=Never --image=busybox:1.36 -- sh -c "wget -qO- --timeout=5 http://gift-dashboard:80/ >/dev/null 2>&1" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "⚠️  The Service exists but connectivity test failed. Check the targetPort matches the container's port."
    exit 1
fi

broadcast "✅ The Gift Dashboard is now reachable! Service created successfully."
exit 0
