#!/bin/bash

cat << 'EOF' > /tmp/rule-kubelinter-env-var.yaml
checks:
  doNotAutoAddDefaults: true
customChecks:
  - name: app-secret-check
    template: env-var
    params:
      name: APP_TOKEN$
EOF

# Run kube-linter on the masterclass-fastapi-app Helm chart.
kube-linter lint /root/masterclass-fastapi-app --config /tmp/rule-kubelinter-env-var.yaml

if [ $? -ne 0 ]; then
  echo "[FAIL] APP_TOKEN is still set as a plaintext environment variable in your Helm chart."
  echo "       The Chief Holiday Officer has flagged this. Remove the APP_TOKEN env var from the deployment."
  exit 1
fi

# Render the Helm template
helm template masterclass /root/masterclass-fastapi-app > /tmp/rendered-deployment.yaml

# Check if the volumeMount is configured correctly
TOKEN_MOUNT_PATH="/app/token"
MOUNT_NAME=$(yq e ".spec.template.spec.containers[0].volumeMounts[] | select(.mountPath == \"$TOKEN_MOUNT_PATH\") | .name" /tmp/rendered-deployment.yaml)
if [ -z "$MOUNT_NAME" ]; then
    echo "[FAIL] No volumeMount found at path '$TOKEN_MOUNT_PATH' in the deployment."
    echo "       Hint: Add a volumeMount under spec.template.spec.containers[0].volumeMounts[] that mounts to $TOKEN_MOUNT_PATH."
    exit 1
fi

# Check if the volume is a secret
IS_SECRET=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | has(\"secret\")" /tmp/rendered-deployment.yaml)
if [ "$IS_SECRET" != "true" ]; then
    echo "[FAIL] The volume '$MOUNT_NAME' mounted at '$TOKEN_MOUNT_PATH' is not backed by a Kubernetes Secret."
    echo "       Hint: The volume definition must use 'secret:' as its source type."
    exit 1
fi

# Check the secret name is correct
SECRET_NAME=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | .secret.secretName" /tmp/rendered-deployment.yaml)
if [ "$SECRET_NAME" != "masterclass-auth" ]; then
    echo "[FAIL] Wrong Secret referenced. The volume points to '$SECRET_NAME', but that is not the coordinates vault."
    echo "       Hint: Run 'kubectl get secrets -n challenge1' to find the correct Secret name."
    exit 1
fi

# Check the secret key maps to credentials.key
SECRET_PATH=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | .secret.items[] | select(.key == \"legacy-sys-token\") | .path" /tmp/rendered-deployment.yaml)
if [ "$SECRET_PATH" != "credentials.key" ]; then
    echo "[FAIL] The secret key 'legacy-sys-token' is not mapped to the required filename."
    echo "       Hint: Use secret.items[] to map the key to a file path. The file must be named 'credentials.key'."
    exit 1
fi

# Check APP_TOKEN_PATH env var is set to the correct file path
APP_TOKEN_PATH_VALUE=$(yq e '.spec.template.spec.containers[0].env[] | select(.name == "APP_TOKEN_PATH") | .value' /tmp/rendered-deployment.yaml)
if [ "$APP_TOKEN_PATH_VALUE" != "${TOKEN_MOUNT_PATH}/credentials.key" ]; then
    echo "[FAIL] The APP_TOKEN_PATH environment variable is missing or points to the wrong location."
    echo "       Expected: '${TOKEN_MOUNT_PATH}/credentials.key'"
    echo "       Got:      '${APP_TOKEN_PATH_VALUE:-<not set>}'"
    echo "       Hint: Set APP_TOKEN_PATH to the full path of the mounted credentials file."
    exit 1
fi

echo "[PASS] The Master Guidance Coordinates are secured. All validation checks passed."
exit 0

