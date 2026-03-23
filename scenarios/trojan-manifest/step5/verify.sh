broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}
kubectl delete clusterpolicies --all --force
kubectl apply -f /var/kyverno-policies/require-non-root.yaml > /dev/null 2>&1

APPLY_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)
APPLY_EXIT=$?

if [ $? -eq 0 ]; then
    broadcast "✅ North Pole approves of your Non Root Configuration!"
else
    broadcast "❌ North Pole needs you to set the Non Root Configuration!"
fi

kubectl apply -f /var/kyverno-policies/require-drop-all.yaml > /dev/null 2>&1
kubectl apply --dry-run=server -f ~/app.yaml

BONUS_EXIT=$?

if [ $? -eq 0 ]; then
    broadcast "🌟 BONUS ACHIEVED: North Pole approves of your Drop All Capabilities Configuration!"
else
    broadcast "❌ North Pole needs you to set the Drop All Capabilities Configuration!"
fi

if [[ $APPLY_OUT -eq 1 || $BONUS -eq 1 ]]; then
    exit 0 
else
    exit 1
fi
