#!/bin/bash

cat << 'EOF' > /tmp/rule-kubelinter-env-var.yaml
checks:
  doNotAutoAddDefaults: true
customChecks:
  - name: app-secret-check
    template: env-var
    params:
      name: APP_TOKEN
  - name: mode-check
    template: env-var
    params:
      name: MODE
      value: "production"
EOF

# Run kube-linter on the masterclass-fastapi-app Helm chart.
kube-linter lint /root/masterclass-fastapi-app --config /tmp/rule-kubelinter-env-var.yaml

if [ $? -ne 0 ]; then
  #echo "kube-linter checks failed."
  exit 1
fi

#echo "kube-linter checks passed."

# Render the Helm template
helm template masterclass /root/masterclass-fastapi-app > /tmp/rendered-deployment.yaml

# Check if the volumeMount is configured correctly
MOUNT_PATH=$(yq e '.spec.template.spec.containers[0].volumeMounts[] | select(.mountPath == "/app/token") | .name' /tmp/rendered-deployment.yaml)
if [ -z "$MOUNT_PATH" ]; then
    #echo "Check failed: No volume found mounted at /app/token."
    exit 1
fi

#echo "Check passed: Volume is correctly mounted at /app/token."

# Check if the volume is a secret
IS_SECRET=$(yq e ".spec.template.spec.volumes[] | select(.name == \"$MOUNT_PATH\") | has(\"secret\")" /tmp/rendered-deployment.yaml)
if [ "$IS_SECRET" != "true" ]; then
    #echo "Check failed: The volume mounted at /app/token must come from a secret."
    exit 1
fi

#echo "Check passed: The volume mounted at /app/token comes from a secret."
exit 0
