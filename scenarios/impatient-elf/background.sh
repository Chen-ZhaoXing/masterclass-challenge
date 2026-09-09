#!/bin/bash
#
# Bring up the "workshop" environment — everything EXCEPT the gift-registry
# Deployment, which foreground.sh applies from the player-facing asset
# (~/app.yaml) so the player can edit it.
#
# Deployed here:
#   1. local-path provisioner + StorageClass (needed for the database PVC)
#   2. namespace + DB secret
#   3. PostgreSQL (StatefulSet + Service)
#   4. the gift-registry Service
#
set -e

until kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done
echo "Cluster is ready!"

SETUP_DIR="/var/impatient-elf"

# The setup assets may land a moment after this script starts, so give them
# a grace period before giving up.
i=0
while [ "$i" -lt 15 ] && [ ! -f "$SETUP_DIR/namespace.yaml" ]; do
    sleep 1
    i=$((i+1))
done
if [ ! -f "$SETUP_DIR/namespace.yaml" ]; then
    echo "✗ could not find the scenario setup manifests in $SETUP_DIR"
    exit 1
fi

echo "==> provisioning local storage"
kubectl apply -f "$SETUP_DIR/local-path-storage.yaml" >/dev/null 2>&1
kubectl -n local-path-storage wait --for=condition=Ready pod -l app=local-path-provisioner --timeout=120s >/dev/null 2>&1 || true

echo "==> creating namespace + DB secret"
kubectl apply -f "$SETUP_DIR/namespace.yaml"
kubectl apply -f "$SETUP_DIR/db-secret.yaml"

echo "==> deploying PostgreSQL"
kubectl apply -f "$SETUP_DIR/postgres.yaml"
kubectl -n workshop wait --for=condition=Ready pod -l app=workshop-db --timeout=180s

echo "==> deploying the gift-registry Service"
kubectl apply -f "$SETUP_DIR/app-service.yaml"

touch /tmp/setup-finished
