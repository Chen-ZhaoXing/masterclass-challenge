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
TARGET="statefulset.yaml"

if [ ! -f ~/"$TARGET" ]; then
    broadcast "❌ Missing ~/$TARGET file!"
    exit 1
fi

# Apply the user's statefulset
kubectl apply -f ~/"$TARGET" >/dev/null 2>&1
APPLY_EXIT=$?

if [ $APPLY_EXIT -ne 0 ]; then
    broadcast "❌ North Pole found some errors while applying your manifest :("
    exit 1
fi

# Query the running cluster to see if the fields were correctly populated
STORAGE_CLASS=$(kubectl get -f ~/"$TARGET" -o jsonpath='{..volumeClaimTemplates[*].spec.storageClassName}')
ACCESS_MODES=$(kubectl get -f ~/"$TARGET" -o jsonpath='{..volumeClaimTemplates[*].spec.accessModes[*]}')

if [[ "${STORAGE_CLASS,,}" == *"local-path"* ]] && [[ "${ACCESS_MODES,,}" == *"readwriteonce"* ]]; then
    broadcast "✅ North Pole approves of your Storage Configuration!"
    exit 0
else
    broadcast "❌ North Pole needs you to correctly set the accessModes to [ReadWriteOnce] and storageClassName to local-path under volumeClaimTemplates."
    exit 1
fi
