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

# Kyverno reports a policy Ready long before its admission webhook is actually
# registered and serving. Releasing the student at that point means their first
# kubectl apply - and their first Check - run with admission control out of the
# path, which silently passes any manifest.
#
# So apply step 1's policy here and block until a manifest that MUST be rejected
# actually is. The student waits through the dots they are already watching, and
# every Check afterwards is instant because enforcement is known to be live.
kubectl apply -f /var/kyverno-policies/require-resource-limits.yaml

cat > /tmp/kyverno-canary.yaml <<'CANARY'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kyverno-canary
  namespace: gift-tracking
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kyverno-canary
  template:
    metadata:
      labels:
        app: kyverno-canary
    spec:
      containers:
        - name: canary
          image: busybox
CANARY

ENFORCING=0
for _ in $(seq 1 60); do
    if ! kubectl apply --dry-run=server -f /tmp/kyverno-canary.yaml >/dev/null 2>&1; then
        ENFORCING=1
        break
    fi
    sleep 2
done

if [ "$ENFORCING" -ne 1 ]; then
    abort_setup "Kyverno never began enforcing policies - admission control is not in the path"
fi

# Remaining policies are applied per step, by each step's background.sh.
touch /tmp/setup-finished
