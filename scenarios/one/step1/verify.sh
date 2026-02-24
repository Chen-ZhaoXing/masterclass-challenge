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
  exit 1
fi

# Render the Helm template
helm template masterclass /root/masterclass-fastapi-app > /tmp/rendered-deployment.yaml

# Check if the volumeMount is configured correctly
TOKEN_MOUNT_PATH="/app/token"
MOUNT_NAME=$(yq e ".spec.template.spec.containers[0].volumeMounts[] | select(.mountPath == \"$TOKEN_MOUNT_PATH\") | .name" /tmp/rendered-deployment.yaml)
if [ -z "$MOUNT_NAME" ]; then
    exit 1
fi

# Check if the volume is a secret
IS_SECRET=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | has(\"secret\")" /tmp/rendered-deployment.yaml)
if [ "$IS_SECRET" != "true" ]; then
    exit 1
fi

# Check the secret name is correct
SECRET_NAME=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | .secret.secretName" /tmp/rendered-deployment.yaml)
if [ "$SECRET_NAME" != "masterclass-auth" ]; then
    exit 1
fi

# Check the secret key maps to credentials.key
SECRET_PATH=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_NAME\") | .secret.items[] | select(.key == \"legacy-sys-token\") | .path" /tmp/rendered-deployment.yaml)
if [ "$SECRET_PATH" != "credentials.key" ]; then
    exit 1
fi

# Check APP_TOKEN_PATH env var is set to the correct file path
APP_TOKEN_PATH_VALUE=$(yq e '.spec.template.spec.containers[0].env[] | select(.name == "APP_TOKEN_PATH") | .value' /tmp/rendered-deployment.yaml)
if [ "$APP_TOKEN_PATH_VALUE" != "${TOKEN_MOUNT_PATH}/credentials.key" ]; then
    exit 1
fi

exit 0
