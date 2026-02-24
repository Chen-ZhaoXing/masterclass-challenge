#!/bin/bash
# Install Helm if not present
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Install Kyverno
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set admissionController.replicas=1

# Wait for Kyverno to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=300s

# Give Kyverno webhooks a moment to fully register
sleep 15

# Apply Kyverno cluster policies to enforce rules
kubectl apply -f ~/kyverno-policies.yaml

touch /tmp/setup-finished
