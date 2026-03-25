#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

TARGET="deployment.yaml"

if [ ! -f ~/"$TARGET" ]; then
    broadcast "❌ Missing ~/$TARGET file!"
    exit 1
fi

# Apply the user's manifests
kubectl apply -f ~/"$TARGET" >/dev/null 2>&1
APPLY_EXIT=$?

if [ $APPLY_EXIT -ne 0 ]; then
    broadcast "❌ Your manifest failed to apply to the cluster. Please check for syntax errors."
    exit 1
fi

# Query the running deployment to find the volume mounted at /app/data
VOL_NAME=$(kubectl get deployment gift-tracker -o jsonpath='{.spec.template.spec.containers[?(@.name=="tracker")].volumeMounts[?(@.mountPath=="/app/data")].name}')

if [ -z "$VOL_NAME" ]; then
    broadcast "❌ North Pole needs you to mount a volume to the exact path '/app/data' inside the 'tracker' container!"
    exit 1
fi

# Retrieve the PVC claim name for that volume from the deployment spec
CLAIM_NAME=$(kubectl get deployment gift-tracker -o jsonpath='{.spec.template.spec.volumes[?(@.name=="'"$VOL_NAME"'")].persistentVolumeClaim.claimName}')

if [ -z "$CLAIM_NAME" ]; then
    broadcast "❌ The volume mounted at /app/data is not backed by a persistentVolumeClaim!"
    exit 1
fi

# Verify the user actually created the PersistentVolumeClaim
kubectl get pvc "$CLAIM_NAME" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The PersistentVolumeClaim '${CLAIM_NAME}' does not exist in the cluster. Did you define and apply it?"
    exit 1
else
    broadcast "✅ North Pole approves: PersistentVolumeClaim '${CLAIM_NAME}' exists and is mounted!"
fi

# Verify the user created the 'mongodb-service' to fix network connectivity
kubectl get service mongodb-service >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The Python app is isolated! North Pole needs you to create the 'mongodb-service' Service so it can route to the database!"
    exit 1
else
    broadcast "✅ North Pole approves: 'mongodb-service' Service was successfully created!"
fi

broadcast "✅ North Pole approves of your solution!"
exit 0
