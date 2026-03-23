broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

kubectl delete clusterpolicies --all --force
kubectl apply -f /var/kyverno/policiesrequire-sa.yaml -n kyverno >/dev/null 2>&1
kubectl apply -f ~/app.yaml

if [ $? -eq 0 ]; then
    kubectl get serviceaccount gift-tracking-sa >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        broadcast "❌ North Pole needs you to create the gift-tracking-sa Service Account!"
        exit 1
    fi

    SA_NAME=$(kubectl get -f ~/app.yaml -o jsonpath='{..serviceAccountName}')
    if [[ ! "$SA_NAME" =~ "gift-tracking-sa" ]]; then
        broadcast "❌ North Pole needs you to set the gift-tracking-sa Service Account in your manifest!"
        exit 1
    fi

    broadcast "✅ North Pole approves of your Service Account!"
    
    # Bonus Check: Look for automountServiceAccountToken in the applied manifest
    # We use recursive JSONPath '..automountServiceAccountToken' so it works for both Pods and Deployments
    TOKEN_MOUNT=$(kubectl get -f ~/app.yaml -o jsonpath='{..automountServiceAccountToken}')
    TOKEN_SA_MOUNT=$(kubectl get sa gift-tracking-sa -o jsonpath='{..automountServiceAccountToken}')
    if [ "$TOKEN_MOUNT" = "false" || "$TOKEN_SA_MOUNT" = "false" ]; then
        broadcast "🌟 BONUS ACHIEVED: Service account token automount disabled!"
    else
        broadcast "❌ Almost there! The bonus requires you to disable automountServiceAccountToken."
    fi
else
    broadcast "❌ North Pole needs you to set the Service Account!"
    exit 1
fi
