## Delete and apply the new policy
kubectl apply -f /var/kyverno-policies/require-http-probes.yaml
sleep 10
touch /tmp/setup-finished