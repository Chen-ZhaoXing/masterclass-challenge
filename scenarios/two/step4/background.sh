kubectl apply -f /var/kyverno-policies/require-non-default-sa.yaml
sleep 5
touch /tmp/setup-finished