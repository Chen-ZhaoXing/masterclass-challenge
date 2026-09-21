_bc_write() {
    # \r\n, not \n: readline leaves the pty in raw mode while it waits for
    # input, so a bare newline is line-feed only and the text lands indented at
    # the cursor column.
    printf '\r\n%s\r\n' "$2" > "$1" 2>/dev/null
    # Nudge the row count so readline redraws the prompt; without this the
    # terminal looks frozen until the student presses Enter.
    rows=$(stty -F "$1" size 2>/dev/null | cut -d' ' -f1)
    if [ -n "$rows" ]; then
        stty -F "$1" rows $((rows + 1)) 2>/dev/null
        stty -F "$1" rows "$rows" 2>/dev/null
    fi
}

broadcast() {
    # Write ONCE. This used to loop over every writable pty, and the Killercoda
    # box has two that both render to the student's terminal - which is why every
    # message appeared twice. Prefer a pty that has a process attached to it; if
    # none does, fall back to writing to all of them so feedback is never lost.
    for pts in /dev/pts/[0-9]*; do
        [ -w "$pts" ] || continue
        if ps -e -o tty= 2>/dev/null | grep -qx "${pts#/dev/}"; then
            _bc_write "$pts" "$1"
            return
        fi
    done
    for pts in /dev/pts/[0-9]*; do
        [ -w "$pts" ] && _bc_write "$pts" "$1"
    done
}
# Kyverno's own policy-validation webhook intermittently times out on a cold
# cluster, so a single apply is not reliable.
apply_policy() {
    for _ in 1 2 3 4 5; do
        POLICY_APPLY_ERR=$(kubectl apply -f "$1" 2>&1) && return 0
        sleep 2
    done
    return 1
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
if ! apply_policy /var/kyverno-policies/require-labels.yaml; then
    broadcast "⚠️  The policy could not be loaded, so your manifest was never actually checked:"
    broadcast "$POLICY_APPLY_ERR"
    exit 1
fi

# Prove THIS step's policy is actually enforcing before grading anything.
# The shared canary violates every policy, so once step 1's require-resources is
# live it is rejected regardless - which let steps 2-5 pass a manifest that only
# ever satisfied step 1. This canary satisfies every earlier policy and breaks
# only require-labels, so a rejection can only have come from require-labels.
cat > /tmp/kyverno-canary-step3.yaml <<'CANARY'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kyverno-canary
  namespace: gift-tracking
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kyverno-canary
  template:
    metadata:
      labels:
        app: kyverno-canary
    spec:
      containers:
        - name: canary
          image: busybox
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "100m"
          livenessProbe:
            httpGet:
              path: /
              port: 8000
          readinessProbe:
            httpGet:
              path: /
              port: 8000
CANARY

ENFORCING=0
for _ in $(seq 1 30); do
    if ! kubectl apply --dry-run=server -f /tmp/kyverno-canary-step3.yaml >/dev/null 2>&1; then
        ENFORCING=1
        break
    fi
    sleep 1
done

if [ "$ENFORCING" -ne 1 ]; then
    broadcast "⚠️  The 'require-labels' policy is not enforcing yet, so your manifest was never actually checked."
    broadcast "   Nothing is wrong with your answer - wait a few seconds and click Check again."
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