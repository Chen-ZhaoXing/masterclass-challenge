kubectl create ns gift-tracking
kubectl apply -f /var/local-path-storage.yaml
kubectl wait --for=condition=Ready pod -l app=local-path-provisioner -n local-path-storage --timeout=60s
kubectl config set-context --current --namespace=gift-tracking
kubectl apply -f /var/config.yaml
touch /tmp/setup-finished