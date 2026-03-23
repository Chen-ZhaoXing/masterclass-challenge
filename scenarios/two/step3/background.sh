## Delete and apply the new policy
kubectl apply -f /var/kyverno-policies/require-labels.yaml --force
sleep 5
touch /tmp/setup-finished