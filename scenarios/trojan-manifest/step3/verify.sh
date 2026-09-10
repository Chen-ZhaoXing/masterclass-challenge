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
POLICY_APPLY_ERR=$(kubectl apply -f /var/kyverno-policies/require-labels.yaml 2>&1)
if [ $? -ne 0 ]; then
    broadcast "⚠️  The policy could not be loaded, so your manifest was never actually checked:"
    broadcast "$POLICY_APPLY_ERR"
    exit 1
fi

# background.sh already blocked until admission control was proven live, so this
# normally passes on the first try. It is a safety net, not a wait: a Ready
# ClusterPolicy does NOT mean the webhook is registered and serving.
ENFORCING=0
for _ in $(seq 1 10); do
    if ! kubectl apply --dry-run=server -f /tmp/kyverno-canary.yaml >/dev/null 2>&1; then
        ENFORCING=1
        break
    fi
    sleep 1
done

if [ "$ENFORCING" -ne 1 ]; then
    broadcast "⚠️  Admission control is not rejecting anything, so your manifest was never actually checked."
    broadcast "   This is an environment problem, not your manifest - please report it."
    exit 1
fi
APPLY_OUT=$(kubectl apply --dry-run=server -f ~/app.yaml 2>&1)

APPLY_OUT_EXIT=$?

if [ $APPLY_OUT_EXIT -eq 0 ]; then
    broadcast "✅ North Pole approves of your Labels!"
    exit 0
else
    broadcast "❌ North Pole needs you to set the Labels!"
    exit 1
fi