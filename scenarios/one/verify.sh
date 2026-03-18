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
  echo "[FAIL] A plaintext secret is still exposed as an environment variable in your Helm chart."
  exit 1
fi

# Render the Helm template and extract only the Deployment document
helm template masterclass /root/masterclass-fastapi-app > /tmp/rendered-all.yaml
yq e 'select(.kind == "Deployment")' /tmp/rendered-all.yaml > /tmp/rendered-deployment.yaml

# Find the secret-backed volume by the expected Secret reference
MOUNT_NAME=$(yq e '.spec.template.spec.volumes[] | select(.secret.secretName == "masterclass-auth") | .name' /tmp/rendered-deployment.yaml | head -n 1)
if [ -z "$MOUNT_NAME" ] || [ "$MOUNT_NAME" = "null" ]; then
  echo "[FAIL] No volume references the expected Secret."
  exit 1
fi

# Check if the mounted volume is secret-backed
IS_SECRET=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | has(\"secret\")" /tmp/rendered-deployment.yaml)
if [ "$IS_SECRET" != "true" ]; then
  echo "[FAIL] The volume '$MOUNT_NAME' is not backed by a Kubernetes Secret."
  exit 1
fi

# Check the secret name is correct
SECRET_NAME=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | .secret.secretName" /tmp/rendered-deployment.yaml)
if [ "$SECRET_NAME" != "masterclass-auth" ]; then
    echo "[FAIL] The volume references the wrong Secret."
    exit 1
fi

# Check the secret key maps to credentials.key
SECRET_PATH=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | .secret.items[] | select(.key == \"legacy-sys-token\") | .path" /tmp/rendered-deployment.yaml)
if [ "$SECRET_PATH" != "credentials.key" ]; then
    echo "[FAIL] The secret key is not mapped to the required filename."
    exit 1
fi

# Resolve mount path for the discovered volume name (do not hardcode path)
TOKEN_MOUNT_PATH=$(yq e ".spec.template.spec.containers[0].volumeMounts[] | select(.name == \"$MOUNT_NAME\") | .mountPath" /tmp/rendered-deployment.yaml | head -n 1)
if [ -z "$TOKEN_MOUNT_PATH" ] || [ "$TOKEN_MOUNT_PATH" = "null" ]; then
  echo "[FAIL] The secret volume is not mounted in the container."
  exit 1
fi

# Check APP_TOKEN_PATH env var is set to the correct file path
APP_TOKEN_PATH_VALUE=$(yq e '.spec.template.spec.containers[0].env[] | select(.name == "APP_TOKEN_PATH") | .value' /tmp/rendered-deployment.yaml)
if [ "$APP_TOKEN_PATH_VALUE" != "${TOKEN_MOUNT_PATH}/credentials.key" ]; then
    echo "[FAIL] The application is not configured to find the credentials file."
    exit 1
fi

echo "[PASS] The Master Guidance Coordinates are secured. All validation checks passed."
exit 0