## Delete and apply the new policy
kubectl delete clusterpolicies --all
kubectl apply -f https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-policies/require-labels.yaml
sleep 10
touch /tmp/setup-finished