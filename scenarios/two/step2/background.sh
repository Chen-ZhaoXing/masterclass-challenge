## Delete and apply the new policy
kubectl delete -f https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-policies/require-resource-limits.yaml

kubectl apply -f https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-policies/require-http-probes.yaml

curl https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-deployments/app.yaml > ~/app.yaml

sleep 5
touch /tmp/setup-finished