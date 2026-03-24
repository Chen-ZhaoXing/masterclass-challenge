#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

# Find any Service that selects app=gift-dashboard
SVC_NAME=$(kubectl get services -o jsonpath='{range .items[?(@.spec.selector.app=="gift-dashboard")]}{.metadata.name}{end}' 2>/dev/null)

if [ -z "$SVC_NAME" ]; then
    broadcast "❌ No Service found that targets the gift-dashboard pods. The deployment is still invisible!"
    exit 1
fi

# Check the Service exposes port 80
SVC_PORT=$(kubectl get service "$SVC_NAME" -o jsonpath='{.spec.ports[0].port}')
if [ "$SVC_PORT" != "80" ]; then
    broadcast "❌ Service '$SVC_NAME' exists but it's not exposing port 80."
    exit 1
fi

# Verify connectivity by resolving the Service DNS
kubectl delete pod dns-test --ignore-not-found >/dev/null 2>&1
kubectl run dns-test --rm -i --restart=Never --image=busybox:1.36 -- sh -c "wget -qO- --timeout=5 http://$SVC_NAME:80/ >/dev/null 2>&1" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "⚠️  Service '$SVC_NAME' exists but connectivity test failed. Check the targetPort matches the container's port."
    exit 1
fi

broadcast "✅ The Gift Dashboard is now reachable via Service '$SVC_NAME'!"
exit 0
