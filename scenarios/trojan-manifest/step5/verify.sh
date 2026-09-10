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

POLICY_APPLY_ERR=$(kubectl apply -f /var/kyverno-policies/require-non-root.yaml 2>&1)
if [ $? -ne 0 ]; then
    broadcast "⚠️  The policy could not be loaded, so your manifest was never actually checked:"
    broadcast "$POLICY_APPLY_ERR"
    exit 1
fi

# The admission webhook re-registers asynchronously after a policy change.
# Grading before it is live would let any manifest through.
kubectl wait --for=condition=Ready clusterpolicy/require-non-root --timeout=90s >/dev/null 2>&1
sleep 5

APPLY_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)
APPLY_EXIT=$?

if [ $APPLY_EXIT -eq 0 ]; then
    broadcast "✅ North Pole approves of your Non Root Configuration!"
else
    broadcast "❌ North Pole needs you to set the Non Root Configuration!"
    exit 1
fi

# Bonus: layered on top of require-non-root, so both must hold. A silenced
# apply here would award the bonus for free.
BONUS_APPLY_ERR=$(kubectl apply -f /var/kyverno-policies/require-drop-all.yaml 2>&1)
if [ $? -ne 0 ]; then
    broadcast "⚠️  The bonus policy could not be loaded, so the bonus was not checked."
    broadcast "$BONUS_APPLY_ERR"
    exit 0
fi

kubectl wait --for=condition=Ready clusterpolicy/require-drop-all --timeout=90s >/dev/null 2>&1
sleep 5

BONUS_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)
BONUS_EXIT=$?

if [ $BONUS_EXIT -eq 0 ]; then
    broadcast "🌟 BONUS ACHIEVED: North Pole approves of your Drop All Capabilities Configuration!"
else
    broadcast "❌ North Pole needs you to set the Drop All Capabilities Configuration!"
fi

exit 0
