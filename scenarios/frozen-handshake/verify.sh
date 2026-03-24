#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

if [ ! -f /tmp/setup-finished ]; then
    broadcast "⚠️  Environment is still being set up. Please wait..."
    exit 1
fi

CHART_DIR="/root/tls-client-chart"
NAMESPACE="challenge4"
RELEASE="challenge4"

# 1) Helm template must render cleanly
TEMPLATE_OUTPUT=$(helm template "$RELEASE" "$CHART_DIR" 2>&1)
if [ $? -ne 0 ]; then
    broadcast "❌ [FAIL] Helm template failed. Fix chart syntax first."
    broadcast "$TEMPLATE_OUTPUT"
    exit 1
fi

echo "$TEMPLATE_OUTPUT" > /tmp/challenge4-rendered.yaml
yq e 'select(.kind == "Deployment")' /tmp/challenge4-rendered.yaml > /tmp/challenge4-deployment.yaml

if [ ! -s /tmp/challenge4-deployment.yaml ]; then
    broadcast "❌ [FAIL] No Deployment found in rendered chart output."
    exit 1
fi

# 2) Must reference the expected certificate secret (dynamic volume name)
SECRET_VOLUME_NAME=$(yq e '.spec.template.spec.volumes[] | select(.secret.secretName == "northpole-ca") | .name' /tmp/challenge4-deployment.yaml | head -n 1)
if [ -z "$SECRET_VOLUME_NAME" ] || [ "$SECRET_VOLUME_NAME" = "null" ]; then
    broadcast "❌ [FAIL] No volume references secret 'northpole-ca'."
    broadcast "Hint: Add a volume under spec.template.spec.volumes[] using secret.secretName: northpole-ca"
    exit 1
fi

# 3) The container must mount that exact volume (dynamic mount path)
MOUNT_PATH=$(yq e ".spec.template.spec.containers[0].volumeMounts[] | select(.name == \"$SECRET_VOLUME_NAME\") | .mountPath" /tmp/challenge4-deployment.yaml | head -n 1)
if [ -z "$MOUNT_PATH" ] || [ "$MOUNT_PATH" = "null" ]; then
    broadcast "❌ [FAIL] The secret-backed volume '$SECRET_VOLUME_NAME' is not mounted in the container."
    broadcast "Hint: Add a volumeMount in spec.template.spec.containers[0].volumeMounts[] using name: $SECRET_VOLUME_NAME"
    exit 1
fi

# 4) TLS_CERT_PATH must point to the mounted cert file
TLS_CERT_PATH=$(yq e '.spec.template.spec.containers[0].env[] | select(.name == "TLS_CERT_PATH") | .value' /tmp/challenge4-deployment.yaml)
EXPECTED_CERT_PATH="${MOUNT_PATH}/ca.crt"
if [ "$TLS_CERT_PATH" != "$EXPECTED_CERT_PATH" ]; then
    broadcast "❌ [FAIL] TLS_CERT_PATH is not aligned with the mounted certificate file."
    broadcast "Expected: $EXPECTED_CERT_PATH"
    broadcast "Got: ${TLS_CERT_PATH:-<not set>}"
    exit 1
fi

# 5) Apply chart and ensure workload becomes available (runtime TLS success)
UPGRADE_OUTPUT=$(helm upgrade --install "$RELEASE" "$CHART_DIR" -n "$NAMESPACE" 2>&1)
if [ $? -ne 0 ]; then
    broadcast "❌ [FAIL] Helm upgrade failed."
    broadcast "$UPGRADE_OUTPUT"
    exit 1
fi

kubectl -n "$NAMESPACE" rollout status deployment/challenge4-tls-client --timeout=120s >/tmp/challenge4-rollout.log 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ [FAIL] Client deployment did not become ready. TLS handshake is likely still failing."
    broadcast "Hint: Check logs with: kubectl logs -n challenge4 deploy/challenge4-tls-client --tail=50"
    exit 1
fi

# 6) Ensure Helm also deploys the simple HTTPS endpoint app
kubectl -n "$NAMESPACE" rollout status deployment/tls-echo --timeout=120s >/tmp/challenge4-app-rollout.log 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ [FAIL] HTTPS endpoint app (deployment/tls-echo) is not ready."
    broadcast "Hint: Ensure Helm deploys the application and service resources."
    exit 1
fi

# 7) Runtime assertion: curl without CA should fail
kubectl exec -n "$NAMESPACE" deploy/challenge4-tls-client -- sh -c 'curl --silent --show-error --fail https://tls-echo.challenge4.svc.cluster.local:8443/ > /tmp/ch4-no-ca.out 2>/tmp/ch4-no-ca.err'
NO_CA_EXIT=$?
if [ "$NO_CA_EXIT" -eq 0 ]; then
    broadcast "❌ [FAIL] Curl without CA certificate unexpectedly succeeded. TLS trust is not being validated."
    exit 1
fi

# 8) Runtime assertion: curl with mounted CA should succeed
WITH_CA_OUTPUT=$(kubectl exec -n "$NAMESPACE" deploy/challenge4-tls-client -- sh -c 'curl --silent --show-error --fail --cacert "$TLS_CERT_PATH" https://tls-echo.challenge4.svc.cluster.local:8443/')
if [ $? -ne 0 ] || ! echo "$WITH_CA_OUTPUT" | grep -q "north-pole-secure-endpoint"; then
    broadcast "❌ [FAIL] Curl with mounted CA certificate failed."
    broadcast "Hint: Confirm TLS_CERT_PATH points to <mountPath>/ca.crt and secret northpole-ca is mounted."
    exit 1
fi

broadcast "✅ [PASS] TLS trust is restored. Certificate is mounted correctly and the secure endpoint is reachable."
broadcast " Here is the flag! "
broadcast "============================================================\n"
broadcast "        n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=        \n"
broadcast "============================================================\n"
exit 0
