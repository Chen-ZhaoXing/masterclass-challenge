#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

# Check if the deployment exists
kubectl get deployment gift-registry >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The 'gift-registry' deployment does not exist. Did you apply the manifest?"
    exit 1
fi

# Check the image name is correct
IMAGE=$(kubectl get deployment gift-registry -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if echo "$IMAGE" | grep -qi "nignx"; then
    broadcast "❌ The image name '$IMAGE' looks like a typo. Check the spelling!"
    exit 1
else
    broadcast "✅ Image name looks correct: $IMAGE"
fi

# Check for running pods
AVAILABLE=$(kubectl get deployment gift-registry -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$AVAILABLE" ] || [ "$AVAILABLE" -lt 1 ]; then
    broadcast "⏳ The deployment exists but pods aren't running yet. Run: kubectl get pods"
    exit 1
else
    broadcast "✅ The 'gift-registry' pod is running!"
fi

broadcast "✅ The Ghost Container has been exorcised!"
exit 0
