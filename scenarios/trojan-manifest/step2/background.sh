## Delete and apply the new policy
kubectl apply -f /var/kyverno-policies/require-http-probes.yaml
touch /tmp/setup-finished