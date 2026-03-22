kubectl delete clusterpolicies --all
kubectl apply -f /var/kyverno-policies/require-non-default-sa.yaml
sleep 10
touch /tmp/setup-finished