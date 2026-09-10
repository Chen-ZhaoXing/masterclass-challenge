#!/bin/bash
# Install Helm if not present
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Pinned deliberately - see scenarios/trojan-manifest/readme.md.
# chart 3.8.2 -> Kyverno v1.18.2
KYVERNO_CHART_VERSION="3.8.2"

# A failure here must still reach the sentinel, otherwise foreground.sh polls
# forever. Record the reason so verify.sh can report it instead of grading a
# cluster that has no policy engine.
KYVERNO_FAILED=/tmp/kyverno-setup-failed
rm -f "$KYVERNO_FAILED"

abort_setup() {
    echo "$1" > "$KYVERNO_FAILED"
    echo "✗ $1"
    touch /tmp/setup-finished
    exit 1
}

helm repo add kyverno https://kyverno.github.io/kyverno/ \
    || abort_setup "could not add the Kyverno Helm repository"
helm repo update

helm install kyverno kyverno/kyverno \
    --version "$KYVERNO_CHART_VERSION" \
    -n kyverno --create-namespace \
    --set admissionController.replicas=1 \
    --set admissionController.podLabels.app=admission \
    || abort_setup "Kyverno chart ${KYVERNO_CHART_VERSION} failed to install"

sleep 15

# Wait for Kyverno to be ready
kubectl wait --for=condition=ready pod -l app=admission -n kyverno --timeout=300s \
    || abort_setup "the Kyverno admission controller did not become ready"

kubectl create ns gift-tracking
kubectl config set-context --current --namespace=gift-tracking

# Give Kyverno webhooks a moment to fully register
sleep 60

# Policies are applied per step, by each step's background.sh and verify.sh.
touch /tmp/setup-finished
