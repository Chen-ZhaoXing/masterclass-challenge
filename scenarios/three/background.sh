#!/bin/bash

# Install Helm if not present
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

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
# This allows Kubernetes nodes to pull from localhost:30500
mkdir -p /etc/containerd/certs.d/localhost:30500
cat <<EOF > /etc/containerd/certs.d/localhost:30500/hosts.toml
[host."http://localhost:30500"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true
EOF

systemctl restart containerd

# Wait for containerd and nodes to come back
sleep 10
kubectl wait --for=condition=ready node --all --timeout=120s

touch /tmp/setup-finished
