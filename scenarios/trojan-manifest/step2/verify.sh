broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "$1" > "$pts" 2>/dev/null
        fi
    done
}
kubectl delete clusterpolicies --all --force
kubectl apply -f /var/kyverno-policies/require-http-probes.yaml > /dev/null 2>&1
APPLY_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)

APPLY_OUT_EXIT=$?

if [ $APPLY_OUT_EXIT -eq 0 ]; then
    broadcast "✅ North Pole approves of your HTTP probes!"
    broadcast "============================================================\n"
    broadcast "          🎉 ALL CHECKS PASSED! Here is the flag!\n           "
    broadcast "        oFQR8lFYiwAIWZtvK6ueR4ece9bIVCUfetfz2Gu/nOs=        \n"
    broadcast "============================================================\n"
    exit 0
else
    broadcast "❌ North Pole needs you to set the HTTP probes!"
    exit 1
fi