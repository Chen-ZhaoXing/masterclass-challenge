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

kubectl create ns gift-tracking \
    || note_failure "could not create the gift-tracking namespace"
kubectl apply -f /var/local-path-storage.yaml \
    || note_failure "could not install the local-path storage provisioner"
kubectl wait --for=condition=Ready pod -l app=local-path-provisioner -n local-path-storage --timeout=60s \
    || note_failure "the local-path storage provisioner did not become ready within 60s"
kubectl config set-context --current --namespace=gift-tracking
kubectl apply -f /var/config.yaml \
    || note_failure "could not apply /var/config.yaml (the app's ConfigMap and Secret)"
touch /tmp/setup-finished
