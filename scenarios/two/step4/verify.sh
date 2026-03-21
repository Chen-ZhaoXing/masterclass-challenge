broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

kubectl apply -f https://raw.githubusercontent.com/touching123/masterclass-challenge-assets/refs/heads/main/kyverno-policies/require-sa.yaml
kubectl apply -f ~/app.yaml

if [ $? -eq 0 ]; then
    broadcast "✅ North Pole approves of your Service Account!"
    
    # Bonus Check: Look for automountServiceAccountToken in the applied manifest
    # We use recursive JSONPath '..automountServiceAccountToken' so it works for both Pods and Deployments
    TOKEN_MOUNT=$(kubectl get -f ~/app.yaml -o jsonpath='{..automountServiceAccountToken}')
    if [ "$TOKEN_MOUNT" = "false" ]; then
        broadcast "🌟 BONUS ACHIEVED: Service account token automount disabled!"
        exit 0
    else
        broadcast "❌ Almost there! The bonus requires you to disable automountServiceAccountToken."
        exit 1
    fi
else
    broadcast "❌ North Pole needs you to set the Service Account!"
    exit 1
fi
