kubectl delete clusterpolicies --all
kubectl apply -f https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-policies/require-sa.yaml
curl https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-deployments/app.yaml > ~/app.yaml
sleep 5
touch /tmp/setup-finished