#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}
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
    broadcast "============================================================\n"
    broadcast "          🎉 ALL CHECKS PASSED! Here is the flag!\n           "
    broadcast "        /4DYxhnFSRwHumwwIs0be+rKbKGAaaHqwmQe8423SpQ=        \n"
    broadcast "============================================================\n"
    exit 0
else
    broadcast "❌ North Pole needs you to correctly set the accessModes to [ReadWriteOnce] and storageClassName to local-path under volumeClaimTemplates."
    exit 1
fi
