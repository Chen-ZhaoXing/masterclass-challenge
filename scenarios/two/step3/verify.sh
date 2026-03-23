broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}
kubectl delete clusterpolicies --all
sleep 5
kubectl apply -f /var/kyverno-policies/require-labels.yaml >/dev/null 2>&1
APPLY_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)
if [ $? -eq 0 ]; then
    broadcast "✅ North Pole approves of your Labels!"
    exit 0
else
    broadcast "❌ North Pole needs you to set the Labels!"
    exit 1
fi
sleep 15