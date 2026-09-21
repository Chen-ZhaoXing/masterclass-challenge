#!/bin/bash

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

if [ ! -f /tmp/setup-finished ]; then
    broadcast "⚠️  Environment is still being set up. Please wait..."
    exit 1
fi

SA="system:serviceaccount:gift-tracking:gift-tracking-sa"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Every check below is an independent API round trip, so they are fired
# concurrently and collected afterwards. Run in series this takes ~8 round
# trips; in parallel it costs roughly one.
probe() {   # probe <slot> <verb> <resource> [namespace]
    if [ -n "${4:-}" ]; then
        kubectl auth can-i "$2" "$3" --as="$SA" -n "$4" >/dev/null 2>&1
    else
        kubectl auth can-i "$2" "$3" --as="$SA" >/dev/null 2>&1
    fi
    echo "$?" > "$TMP/$1"
}

kubectl get serviceaccount gift-tracking-sa -n gift-tracking >/dev/null 2>&1 \
    && echo yes > "$TMP/sa" || echo no > "$TMP/sa" &
kubectl get deployment gift-tracker -n gift-tracking \
    -o jsonpath='{.status.availableReplicas}' >"$TMP/replicas" 2>/dev/null &

probe wildcard      "*"      "*"                                   &
probe del_sec_kube  delete   secrets              kube-system      &
probe get_sec_ns    get      secrets              gift-tracking    &
probe create_pods   create   pods                 gift-tracking    &
probe create_crb    create   clusterrolebindings                   &
probe del_nodes     delete   nodes                                 &

wait

# kubectl auth can-i exits 0 when the action IS allowed.
was_allowed() { [ "$(cat "$TMP/$1" 2>/dev/null)" = "0" ]; }

deny() {    # deny <slot> <description>
    if was_allowed "$1"; then
        broadcast "❌ [FAIL] The workload identity can still $2."
        exit 1
    fi
}

if [ "$(cat "$TMP/sa" 2>/dev/null)" != "yes" ]; then
    broadcast "❌ [FAIL] The gift-tracking workload no longer has an identity in the cluster. The running application depends on it."
    exit 1
fi

AVAILABLE=$(cat "$TMP/replicas" 2>/dev/null)
if [ -z "$AVAILABLE" ] || [ "$AVAILABLE" -lt 1 ]; then
    broadcast "❌ [FAIL] The gift-tracking application is not running."
    exit 1
fi

deny wildcard     "do anything it likes at cluster scope"
deny del_sec_kube "'delete secrets' in namespace 'kube-system'"
deny get_sec_ns   "'get secrets' in namespace 'gift-tracking'"
deny create_pods  "'create pods' in namespace 'gift-tracking'"
deny create_crb   "'create clusterrolebindings' at cluster scope"
deny del_nodes    "'delete nodes' at cluster scope"

broadcast "✅ [PASS] The skeleton key has been revoked. The identity survives and the service is still running."
exit 0
