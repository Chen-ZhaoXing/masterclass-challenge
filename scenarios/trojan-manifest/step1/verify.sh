broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}
kubectl delete clusterpolicies --all --force
kubectl apply -f /var/kyverno-policies/require-resource-limits.yaml >/dev/null 2>&1
APPLY_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)

APPLY_OUT_EXIT=$?

if [ $APPLY_OUT_EXIT -eq 0 ]; then
    broadcast "✅ North Pole approves of your resource requests and limits!"
    broadcast "============================================================\n"
    broadcast "          🎉 ALL CHECKS PASSED! Here is the flag!\n           "
    broadcast "        X5LeUhAIG41t66sZ5rCXSb86J4jhNXBxUU//EOs1iqs=        \n"
    broadcast "============================================================\n"
    exit 0
else
    broadcast "❌ North Pole needs you to set the resource requests and limits"
    exit 1
fi