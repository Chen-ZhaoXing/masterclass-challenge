#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

# Check if the deployment exists
kubectl get deployment sleigh-dashboard >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The 'sleigh-dashboard' deployment does not exist yet. Did you apply the manifest?"
    exit 1
fi

# Check the image tag
IMAGE=$(kubectl get deployment sleigh-dashboard -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)

if echo "$IMAGE" | grep -qE ':latest$'; then
    broadcast "❌ The image is still using the dangerous ':latest' tag! Pin it to a specific version like python:3.13-slim"
    exit 1
fi

if echo "$IMAGE" | grep -qE '^[^:]+$'; then
    broadcast "❌ The image has no tag at all! This defaults to ':latest'. Pin it to a specific version."
    exit 1
fi

broadcast "✅ Image is pinned to: $IMAGE"
broadcast "✅ The Untagged Shipment has been secured!"
broadcast "============================================================\n"
broadcast "          🎉 ALL CHECKS PASSED! Here is the flag!\n           "
broadcast "        lZpF1E5vz1g2HtAEaBVW/lASnyEJ6BfewJjADJ5dJXg=        \n"
broadcast "============================================================\n"
exit 0
