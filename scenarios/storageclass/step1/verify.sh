#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}
if [ ! -f /tmp/setup-finished ]; then
    broadcast "⚠️  Environment is still being set up. Please wait..."
    exit 1
fi

# A failed setup is an environment problem, not the player's; say so before grading.
if [ -f /tmp/setup-failed ]; then
    broadcast "⚠️  The environment did not finish setting up: $(cat /tmp/setup-failed)"
    broadcast "   This is not something you did. Restart the scenario, and tell the facilitator if it happens again."
    exit 1
fi

TARGET="statefulset.yaml"

if [ ! -f ~/"$TARGET" ]; then
    broadcast "❌ Missing ~/$TARGET file!"
    exit 1
fi

# Apply the user's statefulset
kubectl apply -f ~/"$TARGET" >/dev/null 2>&1
APPLY_EXIT=$?

if [ $APPLY_EXIT -ne 0 ]; then
    broadcast "❌ North Pole found some errors while applying your manifest :("
    exit 1
fi

# Query the running cluster to see if the fields were correctly populated
STORAGE_CLASS=$(kubectl get -f ~/"$TARGET" -o jsonpath='{..volumeClaimTemplates[*].spec.storageClassName}')
ACCESS_MODES=$(kubectl get -f ~/"$TARGET" -o jsonpath='{..volumeClaimTemplates[*].spec.accessModes[*]}')

if [[ "${STORAGE_CLASS,,}" == *"local-path"* ]] && [[ "${ACCESS_MODES,,}" == *"readwriteonce"* ]]; then
    broadcast "✅ North Pole approves of your Storage Configuration!"
    exit 0
else
    broadcast "❌ North Pole needs you to correctly set the accessModes to [ReadWriteOnce] and storageClassName to local-path under volumeClaimTemplates."
    exit 1
fi
