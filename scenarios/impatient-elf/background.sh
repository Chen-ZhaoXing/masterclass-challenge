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
until kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done
echo "Cluster is ready!"

# Killercoda preserves the relative path of an asset under its target, so
# "setup/postgres.yaml" -> "/var/impatient-elf/" lands in a setup/ subdirectory.
SETUP_DIR="/var/impatient-elf/setup"

# Any failure below must still reach the sentinel, otherwise foreground.sh
# polls forever and the environment never becomes usable. Record the reason
# instead so verify.sh can report it.
SETUP_FAILED=/tmp/impatient-elf-setup-failed
rm -f "$SETUP_FAILED"

abort_setup() {
    echo "$1" > "$SETUP_FAILED"
    echo "✗ $1"
    touch /tmp/setup-finished
    exit 1
}

# The setup assets may land a moment after this script starts, so give them
# a grace period before giving up.
i=0
while [ "$i" -lt 15 ] && [ ! -f "$SETUP_DIR/namespace.yaml" ]; do
    sleep 1
    i=$((i+1))
done
if [ ! -f "$SETUP_DIR/namespace.yaml" ]; then
    abort_setup "could not find the scenario setup manifests in $SETUP_DIR"
fi

echo "==> provisioning local storage"
kubectl apply -f "$SETUP_DIR/local-path-storage.yaml" >/dev/null 2>&1
kubectl -n local-path-storage wait --for=condition=Ready pod -l app=local-path-provisioner --timeout=120s >/dev/null 2>&1 || true

echo "==> creating namespace + DB secret"
kubectl apply -f "$SETUP_DIR/namespace.yaml" || abort_setup "failed to create the workshop namespace"
kubectl apply -f "$SETUP_DIR/db-secret.yaml" || abort_setup "failed to create the database secret"

echo "==> deploying PostgreSQL"
kubectl apply -f "$SETUP_DIR/postgres.yaml" || abort_setup "failed to apply the PostgreSQL manifests"
kubectl -n workshop wait --for=condition=Ready pod -l app=workshop-db --timeout=180s \
    || abort_setup "PostgreSQL did not become ready within 180s"

echo "==> deploying the gift-registry Service"
kubectl apply -f "$SETUP_DIR/app-service.yaml" || abort_setup "failed to apply the gift-registry Service"

touch /tmp/setup-finished
