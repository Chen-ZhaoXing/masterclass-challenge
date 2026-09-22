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

# Kyverno's own policy webhooks intermittently refuse connections on a cold
# cluster, so a single apply is not reliable.
apply_policy() {
    for _ in 1 2 3 4 5; do
        POLICY_APPLY_ERR=$(kubectl apply -f "$1" 2>&1) && return 0
        sleep 2
    done
    return 1
}

# Re-applying a ClusterPolicy on every Check goes through Kyverno's own policy
# webhooks, which are cold on the first call and time out at 10s - that is what
# made the first Check slow while later ones were instant. background.sh has
# already applied it, so confirm with a plain read and only fall back to an
# apply if it is genuinely missing.
ensure_policy() {   # ensure_policy <file> <policy-name>
    kubectl get clusterpolicy "$2" >/dev/null 2>&1 && return 0
    apply_policy "$1"
}

# --- enforcement gate -------------------------------------------------------
# A non-zero exit from the dry-run is NOT proof the policy is enforcing:
# validate.kyverno.svc-fail is failurePolicy=Fail, so while Kyverno is
# unreachable the API server rejects everything with an InternalError. Require
# the rejection to name the policy we are actually gating on.
gate_policy() {   # gate_policy <canary-file> <policy-name> <attempts>
    GATE_LAST=""
    _n=${3:-15}
    while [ "$_n" -gt 0 ]; do
        if GATE_LAST=$(kubectl apply --dry-run=server -f "$1" 2>&1); then
            :                                   # accepted -> not enforcing yet
        elif printf '%s' "$GATE_LAST" | grep -q "$2"; then
            return 0                            # rejected BY THIS POLICY
        fi
        _n=$((_n - 1))
        [ "$_n" -gt 0 ] && sleep 2
    done
    return 1
}

gate_reason() {   # gate_reason <policy-name>
    if printf '%s' "$GATE_LAST" | grep -Eq 'failed calling webhook|connection refused|context deadline exceeded|InternalError|EOF'; then
        printf 'The policy engine is restarting, so your manifest was never actually checked.'
    else
        printf "The '%s' policy is not enforcing yet, so your manifest was never actually checked." "$1"
    fi
}

if [ ! -f /tmp/setup-finished ]; then
    broadcast "⏳ The environment is still being set up - the policy engine is not running yet."
    broadcast "   Wait for the dots in the terminal to finish, then click Check again."
    exit 1
fi

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
if ! ensure_policy /var/kyverno-policies/require-non-default-sa.yaml require-non-default-sa; then
    broadcast "⚠️  The policy could not be loaded, so your manifest was never actually checked:"
    broadcast "$POLICY_APPLY_ERR"
    exit 1
fi

# This canary satisfies every EARLIER policy and violates only require-non-default-sa,
# so a rejection naming require-non-default-sa can only have come from require-non-default-sa itself.
cat > /tmp/kyverno-canary-step4.yaml <<'CANARY'
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
        app.kubernetes.io/name: gift-tracking-app
        app.kubernetes.io/instance: gift-tracking-app
    spec:
      serviceAccountName: default
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

# Prove require-non-default-sa is enforcing RIGHT NOW, before grading anything.
if ! gate_policy /tmp/kyverno-canary-step4.yaml "require-non-default-sa" 6; then
    broadcast "⚠️  $(gate_reason "require-non-default-sa")"
    broadcast "   Nothing is wrong with your answer - wait a few seconds and click Check again."
    exit 1
fi
# Grade a CREATE, never an UPDATE. The student created this Deployment back in
# step 1, so re-applying the same file is a no-op update - and Kyverno does not
# re-validate one. That is why a manifest with no probes and no labels was
# accepted by steps 2 and 3 while the canary was correctly being rejected:
# enforcement was live, the manifest just was not being evaluated.
# Renaming into a scratch copy makes every check a fresh create.
# --dry-run=server means nothing is persisted under either name.
GRADE_SRC=/tmp/grader-app.yaml
sed '0,/^[[:space:]][[:space:]]name:[[:space:]]*.*$/s//  name: grader-check/' ~/app.yaml > "$GRADE_SRC"
if ! grep -qx '  name: grader-check' "$GRADE_SRC"; then
    broadcast "⚠️  The grader could not rewrite your manifest's metadata.name, so it was not checked."
    broadcast "   This is an environment problem, not your manifest - please report it."
    exit 1
fi
APPLY_OUT=$(kubectl apply --dry-run=server -f "$GRADE_SRC" 2>&1)

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

    # Kyverno's admission path flaps: the same manifest has been seen rejected
    # and then accepted seconds later, so passing the gate above proves nothing
    # about the moment this manifest was graded. Prove it again. An acceptance
    # is only trustworthy if the policy was live on both sides of it.
    if ! gate_policy /tmp/kyverno-canary-step4.yaml "require-non-default-sa" 3; then
        broadcast "⚠️  $(gate_reason "require-non-default-sa")"
        broadcast "   Nothing is wrong with your answer - wait a few seconds and click Check again."
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
    if ! printf '%s' "$APPLY_OUT" | grep -q "require-non-default-sa"; then
        broadcast "⚠️  The policy engine is restarting, so your manifest was never actually checked."
        broadcast "   Nothing is wrong with your answer - wait a few seconds and click Check again."
        exit 1
    fi
    broadcast "❌ North Pole needs you to set the Service Account!"
    exit 1
fi