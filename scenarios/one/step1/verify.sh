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
  echo "❌ MISSION ABORT: APP_TOKEN is still set as a plain environment variable in your Helm chart."
  echo "   The security audit forbids this. Remove the APP_TOKEN env var from your deployment."
  exit 1
fi

# Render the Helm template
helm template masterclass /root/masterclass-fastapi-app > /tmp/rendered-deployment.yaml

# Check if the volumeMount is configured correctly
TOKEN_MOUNT_PATH="/app/token"
MOUNT_NAME=$(yq e ".spec.template.spec.containers[0].volumeMounts[] | select(.mountPath == \"$TOKEN_MOUNT_PATH\") | .name" /tmp/rendered-deployment.yaml)
if [ -z "$MOUNT_NAME" ]; then
    echo "❌ MISSION ABORT: No volumeMount found at path '$TOKEN_MOUNT_PATH' in the deployment."
    echo "   Hint: Add a volumeMount in spec.template.spec.containers[0].volumeMounts[] that mounts to $TOKEN_MOUNT_PATH."
    exit 1
fi

# Check if the volume is a secret
IS_SECRET=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | has(\"secret\")" /tmp/rendered-deployment.yaml)
if [ "$IS_SECRET" != "true" ]; then
    echo "❌ MISSION ABORT: The volume '$MOUNT_NAME' mounted at '$TOKEN_MOUNT_PATH' is not backed by a Kubernetes Secret."
    echo "   Hint: The volume definition must use 'secret:' as its source, not configMap or hostPath."
    exit 1
fi

# Check the secret name is correct
SECRET_NAME=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | .secret.secretName" /tmp/rendered-deployment.yaml)
if [ "$SECRET_NAME" != "masterclass-auth" ]; then
    echo "❌ MISSION ABORT: Wrong Secret referenced. Got '$SECRET_NAME', but the vault is called something else."
    echo "   Hint: Run 'kubectl get secrets -n challenge1' to identify the correct Secret name."
    exit 1
fi

# Check the secret key maps to credentials.key
SECRET_PATH=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | .secret.items[] | select(.key == \"legacy-sys-token\") | .path" /tmp/rendered-deployment.yaml)
if [ "$SECRET_PATH" != "credentials.key" ]; then
    echo "❌ MISSION ABORT: The secret key 'legacy-sys-token' is not mapped to the required filename."
    echo "   Hint: Use 'secret.items[]' to map the key to a specific file path. The file must be named 'credentials.key'."
    exit 1
fi

# Check APP_TOKEN_PATH env var is set to the correct file path
APP_TOKEN_PATH_VALUE=$(yq e '.spec.template.spec.containers[0].env[] | select(.name == "APP_TOKEN_PATH") | .value' /tmp/rendered-deployment.yaml)
if [ "$APP_TOKEN_PATH_VALUE" != "${TOKEN_MOUNT_PATH}/credentials.key" ]; then
    echo "❌ MISSION ABORT: The APP_TOKEN_PATH environment variable is missing or points to the wrong path."
    echo "   Expected: '${TOKEN_MOUNT_PATH}/credentials.key', got: '${APP_TOKEN_PATH_VALUE:-<not set>}'"
    echo "   Hint: Set APP_TOKEN_PATH to the full path of the mounted credentials file."
    exit 1
fi

echo "✅ MISSION ACCOMPLISHED: The vault is secured. All checks passed!"
exit 0
