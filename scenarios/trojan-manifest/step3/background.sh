## Delete and apply the new policy
# Retry: Kyverno's policy-validation webhook times out intermittently on a
# cold cluster, and a silent failure here used to leave require-labels absent
# while the step still graded as if it were live.
for _ in 1 2 3 4 5; do
    kubectl apply -f /var/kyverno-policies/require-labels.yaml && break
    sleep 2
done