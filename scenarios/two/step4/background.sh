kubectl apply -f /var/kyverno-policies/require-non-default-sa.yaml --force
sleep 5
touch /tmp/setup-finished