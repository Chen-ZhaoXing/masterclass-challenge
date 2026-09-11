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

# Killercoda does NOT keep an asset's subdirectory when the asset is a single
# file: "setup/postgres.yaml" with target "/var/impatient-elf/" lands at
# /var/impatient-elf/postgres.yaml. Confirmed on a live session (2026-09-11),
# where looking in /var/impatient-elf/setup/ aborted setup before anything was
# created. The setup/ subdirectory is still accepted as a fallback, so this
# keeps working if the upload behaviour ever changes.
ASSET_ROOT="/var/impatient-elf"
SETUP_DIR=""

find_setup_dir() {
    for d in "$ASSET_ROOT" "$ASSET_ROOT/setup"; do
        if [ -f "$d/namespace.yaml" ]; then
            SETUP_DIR="$d"
            return 0
        fi
    done
    return 1
}

# Any failure below must still reach the sentinel, otherwise foreground.sh
# polls forever and the environment never becomes usable. Record the reason
# instead so foreground.sh and verify.sh can report it.
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
until find_setup_dir || [ "$i" -ge 15 ]; do
    sleep 1
    i=$((i+1))
done
if [ -z "$SETUP_DIR" ]; then
    abort_setup "could not find the scenario setup manifests in $ASSET_ROOT or $ASSET_ROOT/setup"
fi
echo "Using setup manifests from $SETUP_DIR"

echo "==> provisioning local storage"
kubectl apply -f "$SETUP_DIR/local-path-storage.yaml" >/dev/null 2>&1
# `rollout status`, not `wait ... -l`: see the note on the PostgreSQL wait below.
kubectl -n local-path-storage rollout status deployment/local-path-provisioner --timeout=120s >/dev/null 2>&1 || true

echo "==> creating namespace + DB secret"
kubectl apply -f "$SETUP_DIR/namespace.yaml" || abort_setup "failed to create the workshop namespace"
kubectl apply -f "$SETUP_DIR/db-secret.yaml" || abort_setup "failed to create the database secret"

echo "==> deploying PostgreSQL"
kubectl apply -f "$SETUP_DIR/postgres.yaml" || abort_setup "failed to apply the PostgreSQL manifests"
# `kubectl wait -l <selector>` does NOT wait for the Pod to exist: if the
# StatefulSet controller hasn't created workshop-db-0 yet at this instant, it
# exits immediately with "no matching resources found" and --timeout never
# applies. Observed on a live session (2026-09-11): setup aborted claiming
# PostgreSQL wasn't ready while workshop-db-0 was 1/1 Running with the PVC
# bound and the image pulled in under 8s. `rollout status` waits on the
# controller instead, so a not-yet-created Pod is a state it waits through
# rather than an error.
kubectl -n workshop rollout status statefulset/workshop-db --timeout=180s >/dev/null 2>&1 \
    || abort_setup "PostgreSQL did not become ready within 180s. Pod state: $(kubectl -n workshop get pod -l app=workshop-db --no-headers 2>&1 | tr '\n' ';' | head -c 300)"

echo "==> deploying the gift-registry Service"
kubectl apply -f "$SETUP_DIR/app-service.yaml" || abort_setup "failed to apply the gift-registry Service"

touch /tmp/setup-finished
