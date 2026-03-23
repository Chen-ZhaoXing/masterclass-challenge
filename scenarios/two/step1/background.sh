kubectl delete clusterpolicies --all
sleep 5
kubectl apply -f /var/kyverno-policies/require-resource-limits.yaml
touch /tmp/setup-finished