# Retry: Kyverno's policy-validation webhook times out intermittently on a
# cold cluster, and a silent failure here used to leave require-non-root absent
# while the step still graded as if it were live.
for _ in 1 2 3 4 5; do
    kubectl apply -f /var/kyverno-policies/require-non-root.yaml && break
    sleep 2
done