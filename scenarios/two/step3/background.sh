## Delete and apply the new policy
kubectl apply -f /var/kyverno-policies/require-labels.yaml
sleep 5
touch /tmp/setup-finished