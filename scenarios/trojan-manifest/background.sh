#!/bin/bash
printf %s "2026-09-21-r4" > /tmp/scenario-build
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
# This apply used to have no error check. On a cold cluster Kyverno's own
# policy webhook is not serving yet even though the admission pod reports
# Ready, so it fails with "connection refused" - and then NO ClusterPolicy
# exists at all. Retry until it lands.
POLICY_OK=0
for _ in $(seq 1 60); do
    if kubectl apply -f /var/kyverno-policies/require-resource-limits.yaml >/dev/null 2>&1; then
        POLICY_OK=1
        break
    fi
    sleep 2
done
[ "$POLICY_OK" -ne 1 ] && abort_setup "the first Kyverno policy could not be applied"

# Kyverno rebuilds kyverno-resource-validating-webhook-cfg from the policies
# that exist. With no policy it is EMPTY - no rules, no sideEffects - so the
# API server sends it nothing and every manifest is accepted. Observed live:
#
#   kyverno-resource-validating-webhook-cfg  sideEffects=  rules=
#
# That, not a flapping engine, is why manifests passed steps they should have
# failed. Wait for the config to actually carry rules before going further.
WEBHOOK_OK=0
for _ in $(seq 1 60); do
    RULES=$(kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg               -o jsonpath='{.webhooks[*].rules[*].resources}' 2>/dev/null)
    if [ -n "$RULES" ]; then
        WEBHOOK_OK=1
        break
    fi
    sleep 2
done
[ "$WEBHOOK_OK" -ne 1 ] && abort_setup "Kyverno never registered an admission rule for any resource"

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

# Two things the old loop got wrong. A rejection is not proof the policy is
# enforcing - while Kyverno is unreachable, failurePolicy=Fail rejects
# everything - so require the rejection to name require-resources. And Kyverno
# flaps, so require it to hold three times in a row before releasing the
# student, rather than catching one lucky moment.
ENFORCING=0
STREAK=0
for _ in $(seq 1 45); do
    if CANARY_OUT=$(kubectl apply --dry-run=server -f /tmp/kyverno-canary.yaml 2>&1); then
        STREAK=0
    elif printf '%s' "$CANARY_OUT" | grep -q "require-resources"; then
        STREAK=$((STREAK + 1))
        if [ "$STREAK" -ge 3 ]; then
            ENFORCING=1
            break
        fi
    else
        STREAK=0
    fi
    sleep 2
done

if [ "$ENFORCING" -ne 1 ]; then
    abort_setup "Kyverno never began enforcing policies - admission control is not in the path"
fi

# Remaining policies are applied per step, by each step's background.sh.
touch /tmp/setup-finished
