## Delete and apply the new policy
kubectl delete clusterpolicies --all
kubectl apply -f /var/kyverno-policies/require-http-probes.yaml -n kyverno

sleep 10
touch /tmp/setup-finished