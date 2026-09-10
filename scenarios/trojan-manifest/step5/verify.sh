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

# The step's background.sh already applied this policy when the step loaded, so
# this is normally a no-op. Policies accumulate across steps on purpose: a
# manifest has to keep satisfying everything it satisfied earlier, which is how
# admission control behaves in reality. Nothing is deleted, so Kyverno's webhook
# is never torn down and there is no re-registration race to wait out.
POLICY_APPLY_ERR=$(kubectl apply -f /var/kyverno-policies/require-non-root.yaml 2>&1)
if [ $? -ne 0 ]; then
    broadcast "⚠️  The policy could not be loaded, so your manifest was never actually checked:"
    broadcast "$POLICY_APPLY_ERR"
    exit 1
fi

# Normally already True, so this exits on the first pass.
for _ in $(seq 1 10); do
    [ "$(kubectl get clusterpolicy require-non-root -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = "True" ] && break
    sleep 1
done

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

BONUS_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)
BONUS_EXIT=$?

if [ $BONUS_EXIT -eq 0 ]; then
    broadcast "🌟 BONUS ACHIEVED: North Pole approves of your Drop All Capabilities Configuration!"
else
    broadcast "❌ North Pole needs you to set the Drop All Capabilities Configuration!"
fi

exit 0
