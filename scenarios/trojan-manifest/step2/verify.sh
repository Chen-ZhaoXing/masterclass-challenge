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

POLICY_APPLY_ERR=$(kubectl apply -f /var/kyverno-policies/require-http-probes.yaml 2>&1)
if [ $? -ne 0 ]; then
    broadcast "⚠️  The policy could not be loaded, so your manifest was never actually checked:"
    broadcast "$POLICY_APPLY_ERR"
    exit 1
fi

# The admission webhook re-registers asynchronously after a policy change.
# Grading before it is live would let any manifest through.
kubectl wait --for=condition=Ready clusterpolicy/require-probes --timeout=90s >/dev/null 2>&1
sleep 5
APPLY_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)

APPLY_OUT_EXIT=$?

if [ $APPLY_OUT_EXIT -eq 0 ]; then
    broadcast "✅ North Pole approves of your HTTP probes!"
    exit 0
else
    broadcast "❌ North Pole needs you to set the HTTP probes!"
    exit 1
fi