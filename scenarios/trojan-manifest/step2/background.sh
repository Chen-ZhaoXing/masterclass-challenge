## Delete and apply the new policy
# Retry: Kyverno's policy-validation webhook times out intermittently on a
# cold cluster, and a silent failure here used to leave require-probes absent
# while the step still graded as if it were live.
for _ in 1 2 3 4 5; do
    kubectl apply -f /var/kyverno-policies/require-http-probes.yaml && break
    sleep 2
done
touch /tmp/setup-finished