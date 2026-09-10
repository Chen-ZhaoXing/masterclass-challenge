#!/bin/bash

# --- setup guard ------------------------------------------------------------
# foreground.sh waits for /tmp/setup-finished. Touch it on every exit, so a
# failure can never leave the terminal waiting forever, and record the first
# failed step so foreground.sh and verify.sh can report it instead of the
# player debugging a half-built environment.
SETUP_FAILED=/tmp/setup-failed
rm -f "$SETUP_FAILED"
note_failure() { [ -f "$SETUP_FAILED" ] || echo "$1" > "$SETUP_FAILED"; echo "✗ $1"; }
trap 'touch /tmp/setup-finished' EXIT

until kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done

kubectl create namespace gift-tracking >/dev/null 2>&1
kubectl config set-context --current --namespace=gift-tracking >/dev/null 2>&1

kubectl create configmap gift-tracking-config -n gift-tracking \
    --from-literal=ROUTE_MODE=production \
    --from-literal=SLEIGH_ALTITUDE=1200 \
    --from-literal=LOG_LEVEL=info >/dev/null 2>&1

kubectl create secret generic naughty-list -n gift-tracking \
    --from-literal=entries=classified >/dev/null 2>&1

# Without this binding there is no skeleton key to revoke, and step 1 would pass
# before the player has done anything.
kubectl apply -f "$HOME/rbac.yaml" >/dev/null 2>&1 \
    || note_failure "could not apply ~/rbac.yaml, so the cluster-admin binding this challenge is about was never created"

kubectl apply -f - >/dev/null 2>&1 <<'MANIFEST' || note_failure "could not create the gift-tracker Deployment"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gift-tracker
  namespace: gift-tracking
  labels:
    app: gift-tracker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gift-tracker
  template:
    metadata:
      labels:
        app: gift-tracker
    spec:
      serviceAccountName: gift-tracking-sa
      containers:
        - name: tracker
          image: nginx:1.25
          ports:
            - containerPort: 80
          envFrom:
            - configMapRef:
                name: gift-tracking-config
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "200m"
MANIFEST

kubectl wait --for=condition=available deployment/gift-tracker \
    -n gift-tracking --timeout=180s >/dev/null 2>&1 \
    || note_failure "the gift-tracker Deployment did not become available within 180s"

touch /tmp/setup-finished
