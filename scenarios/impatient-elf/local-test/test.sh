#!/usr/bin/env bash
#
# Local end-to-end test for "The Impatient Elf" (kind or minikube).
#
# Usage:
#   ./local-test/test.sh deploy-fixed       # provision, deploy the fix, and apply the reference solution
#   ./local-test/test.sh observe [SECONDS]  # watch the Pod + logs for a while (default 60)
#   ./local-test/test.sh health             # hit /healthz from inside the Pod
#   ./local-test/test.sh cleanup            # delete the workshop namespace
#
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$SCENARIO_DIR/../.." && pwd)"
APP_SRC="$REPO_ROOT/gift-registry-app"
SOLUTION="$REPO_ROOT/solution/impatient-elf/app.yaml"

CLUSTER="${CLUSTER:-elf}"
REGISTRY="${REGISTRY:-newbieshine}"
TAG_APP="${TAG_APP:-2.4.1}"
TAG_ELF="${TAG_ELF:-1.7.0}"
NS=workshop

cmd_build() {
  echo "==> building ${REGISTRY}/gift-registry:${TAG_APP}"
  docker build -t "${REGISTRY}/gift-registry:${TAG_APP}" "$APP_SRC"
  echo "==> building ${REGISTRY}/elf:${TAG_ELF}"
  docker build -f "$APP_SRC/Dockerfile.elf" -t "${REGISTRY}/elf:${TAG_ELF}" "$APP_SRC"
}

cmd_load() {
  echo "==> loading images into kind cluster '${CLUSTER}'"
  kind load docker-image "${REGISTRY}/gift-registry:${TAG_APP}" --name "${CLUSTER}"
  kind load docker-image "${REGISTRY}/elf:${TAG_ELF}" --name "${CLUSTER}"
}

cmd_deploy_fixed() {
  echo "==> provisioning local storage (same as background.sh)"
  kubectl apply -f "$SCENARIO_DIR/assets/setup/local-path-storage.yaml"
  kubectl -n local-path-storage wait --for=condition=Ready pod -l app=local-path-provisioner --timeout=120s || true
  kubectl apply -f "$SCENARIO_DIR/assets/setup/namespace.yaml"
  kubectl apply -f "$SCENARIO_DIR/assets/setup/db-secret.yaml"
  kubectl apply -f "$SCENARIO_DIR/assets/setup/postgres.yaml"
  kubectl -n "$NS" wait --for=condition=Ready pod -l app=workshop-db --timeout=180s
  kubectl apply -f "$SCENARIO_DIR/assets/setup/app-service.yaml"
  echo "==> deploying the gift-registry Deployment"
  kubectl apply -f "$SOLUTION"
  echo "expected: fresh Pod, elf initContainer runs to completion, then 1/1 Running"
}

cmd_observe() {
  local how_long="${1:-60}"
  echo "==> observing for ${how_long}s"
  kubectl -n "$NS" get pods -l 'app in (gift-registry,workshop-db)'
  kubectl -n "$NS" get events --sort-by=.lastTimestamp | tail -15
  kubectl -n "$NS" logs -l app=gift-registry --all-containers --tail=40 || true
}

cmd_health() {
  kubectl -n "$NS" exec deploy/gift-registry -- \
    python -c 'import urllib.request; print(urllib.request.urlopen("http://127.0.0.1:8000/healthz", timeout=10).read().decode())'
}

cmd_cleanup() {
  kubectl delete namespace "$NS" --ignore-not-found
}

case "${1:-deploy-fixed}" in
  build)          cmd_build ;;
  load)           cmd_load ;;
  deploy-fixed)   cmd_deploy_fixed ;;
  observe)        cmd_observe "${2:-60}" ;;
  health)         cmd_health ;;
  cleanup)        cmd_cleanup ;;
  *)
    grep '^# ' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
