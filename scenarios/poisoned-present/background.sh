#!/bin/bash

# Install Docker if not present (Killercoda k8s images have containerd but may lack Docker CLI)
if ! command -v docker &> /dev/null; then
    apt-get update && apt-get install -y docker.io
fi

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
kubectl wait --for=condition=ready pod -l app=registry -n registry --timeout=120s

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
systemctl restart containerd

# Wait for containerd and nodes to come back
sleep 10
kubectl wait --for=condition=ready node --all --timeout=120s

# Install Trivy
apt-get update
apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install -y trivy

# Pre-fetch the vulnerability DB now, once, while there's a terminal-free window.
# verify.sh runs with --skip-db-update so it never depends on the network, which
# makes this download load-bearing: without it every later scan fails on a
# missing DB. Retry a few times rather than trusting a single attempt.
DB_OK=0
for attempt in 1 2 3; do
    if trivy image --download-db-only; then
        DB_OK=1
        break
    fi
    echo "Trivy DB download attempt ${attempt} failed; retrying in 5s..."
    sleep 5
done

if [ "$DB_OK" -ne 1 ]; then
    # Leave a marker so verify.sh can report the real cause instead of failing
    # the student for an environment problem they did not create.
    touch /tmp/trivy-db-failed
    echo "WARNING: Trivy vulnerability DB could not be downloaded."
fi

# Pre-pull both base images so builds during the challenge are fast:
# the old one the rogue elves used, and the current one students will likely land on.
docker pull python:3.9-slim &
docker pull python:3.13-slim &
wait

touch /tmp/setup-finished
