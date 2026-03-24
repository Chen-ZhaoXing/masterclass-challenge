#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

# Check if the Secret exists
kubectl get secret db-credentials >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The Secret 'db-credentials' does not exist. Create it with: kubectl create secret generic db-credentials --from-literal=DB_PASSWORD=NorthPole2025!"
    exit 1
else
    broadcast "✅ Secret 'db-credentials' exists!"
fi

# Check if the deployment exists
kubectl get deployment gift-database-client >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The 'gift-database-client' deployment does not exist. Did you apply the manifest?"
    exit 1
fi

# Check that DB_PASSWORD is no longer hardcoded
HARDCODED=$(kubectl get deployment gift-database-client -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_PASSWORD")].value}' 2>/dev/null)
if [ -n "$HARDCODED" ]; then
    broadcast "❌ The DB_PASSWORD is still hardcoded as a plaintext value! Replace it with a secretKeyRef."
    exit 1
else
    broadcast "✅ DB_PASSWORD is no longer hardcoded!"
fi

# Check that it's using secretKeyRef
SECRET_REF=$(kubectl get deployment gift-database-client -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_PASSWORD")].valueFrom.secretKeyRef.name}' 2>/dev/null)
if [ -z "$SECRET_REF" ]; then
    broadcast "❌ DB_PASSWORD is not using a secretKeyRef. Update the env to reference the 'db-credentials' Secret."
    exit 1
else
    broadcast "✅ DB_PASSWORD is sourced from Secret: $SECRET_REF"
fi

broadcast "✅ The Hardcoded Password has been secured! No more plaintext secrets!"

broadcast "============================================================\n"
broadcast "          🎉 ALL CHECKS PASSED! Here is the flag!\n           "
broadcast "        LJhPsjLJ/qho+Y+tKgb4g8posKPyR3M4j/cA73QW96k=        \n"
broadcast "============================================================\n"

exit 0
