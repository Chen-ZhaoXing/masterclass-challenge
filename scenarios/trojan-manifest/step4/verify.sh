broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}

if [ -f /tmp/kyverno-setup-failed ]; then
    broadcast "⚠️  The policy engine did not install correctly: $(cat /tmp/kyverno-setup-failed)"
    broadcast "   This is an environment problem, not your manifest - please report it."
    exit 1
fi

kubectl delete clusterpolicies --all >/dev/null 2>&1

POLICY_APPLY_ERR=$(kubectl apply -f /var/kyverno-policies/require-non-default-sa.yaml 2>&1)
if [ $? -ne 0 ]; then
    broadcast "⚠️  The policy could not be loaded, so your manifest was never actually checked:"
    broadcast "$POLICY_APPLY_ERR"
    exit 1
fi

# The admission webhook re-registers asynchronously after a policy change.
# Grading before it is live would let any manifest through.
kubectl wait --for=condition=Ready clusterpolicy/require-non-default-sa --timeout=90s >/dev/null 2>&1
sleep 5
APPLY_OUT=$(kubectl apply -f ~/app.yaml --dry-run=server 2>&1)

APPLY_OUT_EXIT=$?

if [ $APPLY_OUT_EXIT -eq 0 ]; then
    kubectl get serviceaccount gift-tracking-sa >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        broadcast "❌ North Pole needs you to create the gift-tracking-sa Service Account!"
        exit 1
    fi

    SA_NAME=$(grep 'serviceAccountName' ~/app.yaml | awk '{print $2}' | tr -d '\r')
    if [[ "$SA_NAME" != "gift-tracking-sa" ]]; then
        broadcast "❌ North Pole needs you to set the gift-tracking-sa Service Account in your manifest!"
        exit 1
    fi

    broadcast "✅ North Pole approves of your Service Account!"
    
    # Bonus Check: Look for automountServiceAccountToken in the manifest or on the SA
    TOKEN_MOUNT=$(grep 'automountServiceAccountToken' ~/app.yaml | awk '{print $2}' | tr -d '\r')
    TOKEN_SA_MOUNT=$(kubectl get sa gift-tracking-sa -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null)
    if [[ "$TOKEN_MOUNT" = "false" || "$TOKEN_SA_MOUNT" = "false" ]]; then
        broadcast "🌟 BONUS ACHIEVED: Service account token automount disabled!"
    else
        broadcast "❌ Almost there! The bonus requires you to disable automountServiceAccountToken."
    fi
else
    broadcast "❌ North Pole needs you to set the Service Account!"
    exit 1
fi