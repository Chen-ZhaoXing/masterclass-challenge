#!/bin/bash
# Install Helm if not present
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Install Kyverno
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set admissionController.replicas=1 --set admissionController.podLabels.app=admission

sleep 15

# Wait for Kyverno to be ready
kubectl wait --for=condition=ready pod -l app=admission -n kyverno --timeout=300s
kubectl create ns gift-tracking
kubectl config set-context --current --namespace=gift-tracking

# Give Kyverno webhooks a moment to fully register
sleep 15

# Apply Kyverno cluster policies to enforce rules
touch /tmp/setup-finished