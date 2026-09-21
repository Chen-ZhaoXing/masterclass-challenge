#!/bin/bash

# --- setup guard ------------------------------------------------------------
# foreground.sh waits for /tmp/setup-finished. Touch it on every exit, so a
# failure can never leave the terminal waiting forever, and record the first
# failed step so foreground.sh and verify.sh can report it instead of the
# player debugging a half-built environment.
SETUP_FAILED=/tmp/setup-failed
rm -f "$SETUP_FAILED"
note_failure() { [ -f "$SETUP_FAILED" ] || echo "$1" > "$SETUP_FAILED"; echo "✗ $1"; }
trap 'touch /tmp/setup-finished' EXIT

# Install Docker if not present (Killercoda k8s images have containerd but may lack Docker CLI)
if ! command -v docker &> /dev/null; then
    apt-get update && apt-get install -y docker.io
fi
command -v docker >/dev/null 2>&1 || note_failure "Docker could not be installed"

# Allow students to use 'podman' as an alias for 'docker'
echo 'alias podman=docker' >> ~/.bashrc

# Deploy a Docker Registry inside the cluster
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: registry
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: registry-data
              mountPath: /var/lib/registry
      volumes:
        - name: registry-data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: registry
spec:
  type: NodePort
  selector:
    app: registry
  ports:
    - port: 5000
      targetPort: 5000
      nodePort: 30500
EOF

# Wait for registry to be ready
kubectl wait --for=condition=ready pod -l app=registry -n registry --timeout=120s \
    || note_failure "the in-cluster registry at localhost:30500 did not become ready within 120s"

# Configure containerd to trust the local insecure registry
mkdir -p /etc/containerd/certs.d/localhost:30500
cat <<EOF > /etc/containerd/certs.d/localhost:30500/hosts.toml
[host."http://localhost:30500"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true
EOF

# Configure Docker daemon to trust the insecure registry
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries": ["localhost:30500"]
}
EOF

systemctl restart docker || true
systemctl restart containerd \
    || note_failure "containerd could not be restarted after trusting the local registry"

# Wait for containerd and nodes to come back
sleep 10
kubectl wait --for=condition=ready node --all --timeout=120s \
    || note_failure "the node did not become ready again after containerd restarted"

# Pre-pull the fat base image so the build doesn't take forever
docker pull python:3.13 &
docker pull python:3.13-slim &
wait

touch /tmp/setup-finished
