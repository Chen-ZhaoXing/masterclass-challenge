#!/bin/bash
# Killercoda runs this the moment the step opens, concurrently with the
# scenario's own background.sh. Signalling readiness here released the
# student while Kyverno was still installing, so the sentinel is now owned
# solely by the scenario background.sh. Wait for it before touching any
# policy: before Kyverno is installed the ClusterPolicy CRD does not exist
# and every apply below would fail silently.
for _ in $(seq 1 180); do
    [ -f /tmp/setup-finished ] && break
    sleep 2
done

for _ in 1 2 3 4 5; do
    kubectl apply -f /var/kyverno-policies/require-non-root.yaml && break
    sleep 2
done

# Pre-warm. kubectl apply returns before Kyverno has rebuilt
# kyverno-resource-validating-webhook-cfg to include require-non-root, so the first
# Check on this step used to pay that delay inside verify.sh - long enough to
# trip Killercoda's own verify timeout. Absorb it here instead, while the
# student is still reading the step. verify.sh writes this same canary and
# keeps its own shorter gate as a safety net.
cat > /tmp/kyverno-canary-step5.yaml <<'CANARY'
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
        app.kubernetes.io/name: gift-tracking-app
        app.kubernetes.io/instance: gift-tracking-app
    spec:
      serviceAccountName: kyverno-canary-sa
      containers:
        - name: canary
          image: busybox
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "100m"
          livenessProbe:
            httpGet:
              path: /
              port: 8000
          readinessProbe:
            httpGet:
              path: /
              port: 8000
CANARY

for _ in $(seq 1 30); do
    CANARY_OUT=$(kubectl apply --dry-run=server -f /tmp/kyverno-canary-step5.yaml 2>&1) && { sleep 2; continue; }
    printf '%s' "$CANARY_OUT" | grep -q "require-non-root" && break
    sleep 2
done

exit 0
