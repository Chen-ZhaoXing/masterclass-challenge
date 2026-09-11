#!/bin/bash
#
# Step 1 verification: the Deployment was actually fixed (elf's work is now
# an initContainer, no longer a regular container) AND the shop is healthy
# (Pod 1/1 Running, zero restarts, /healthz 200, catalog populated).

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
            rows=$(stty -F "$pts" size 2>/dev/null | cut -d' ' -f1)
            if [ -n "$rows" ]; then
                stty -F "$pts" rows $((rows + 1)) 2>/dev/null
                stty -F "$pts" rows "$rows" 2>/dev/null
            fi
        fi
    done
}

if [ ! -f /tmp/setup-finished ]; then
    broadcast "⚠️  Environment is still being set up. Please wait..."
    exit 1
fi

if [ -f /tmp/impatient-elf-setup-failed ]; then
    broadcast "⚠️  The environment did not finish setting up: $(cat /tmp/impatient-elf-setup-failed)"
    broadcast "   This is not your fault - please report it to the workshop staff."
    exit 1
fi

NS=workshop
DEPLOY=gift-registry
APP_LABEL="app=gift-registry"

fail() {
    broadcast "❌ [FAIL] $1"
    broadcast "  Current state: $(kubectl -n "$NS" get pods -l "$APP_LABEL" --no-headers 2>/dev/null | head -1)"
    exit 1
}

kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1 \
  || { broadcast "❌ [FAIL] I can't find the $DEPLOY Deployment in namespace $NS — did it get deleted? Recreate it with the fixed spec."; exit 1; }

# 1) The elf must no longer be a regular container.
ELF_REG=$(kubectl -n "$NS" get deploy "$DEPLOY" \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="elf")].name}' 2>/dev/null)
[ -z "$ELF_REG" ] \
  || fail "the 'elf' is still declared under containers: — regular containers all start at the same instant, in parallel with the app. It belongs in initContainers:"

# 2) The elf's rebuild must now be an initContainer (and wait-for-db must survive).
INIT_NAMES=$(kubectl -n "$NS" get deploy "$DEPLOY" \
  -o jsonpath='{.spec.template.spec.initContainers[*].name}' 2>/dev/null)
echo "$INIT_NAMES" | grep -qw 'wait-for-db' \
  || fail "wait-for-db disappeared from initContainers: — it must keep doing its job."
echo "$INIT_NAMES" | grep -qw 'elf' \
  || fail "the 'elf' is not in initContainers: yet — its catalog rebuild (migrate + restock) must run to completion there, after wait-for-db, before the shop starts."

# 3) The shop container must still be declared (don't cheat by deleting it).
CONTAINER_NAMES=$(kubectl -n "$NS" get deploy "$DEPLOY" \
  -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null)
echo "$CONTAINER_NAMES" | grep -Eq 'gift-registry|shop|app|registry' \
  || fail "the shop container is missing from containers: — the fix is to re-order the work, not to delete the app."

# 4) A 1/1 Running gift-registry Pod must exist (any terminating old Pod is ignored).
POD_LINES=$(kubectl -n "$NS" get pod -l "$APP_LABEL" --no-headers 2>/dev/null)
echo "$POD_LINES" | grep -Eq '^[-A-Za-z0-9.]+ +1/1 +Running' \
  || fail "no gift-registry Pod is '1/1 Running' yet. The elf now works *before* the shop starts, so a fresh boot takes a little longer — wait a moment, then try again."

# 5) That healthy Pod's shop container must have started cleanly (zero restarts).
RESTARTS=$(kubectl -n "$NS" get pod -l "$APP_LABEL" \
  -o jsonpath='{.items[?(@.status.phase=="Running" && @.status.containerStatuses[0].ready)].status.containerStatuses[?(@.name=="gift-registry")].restartCount}' 2>/dev/null | head -1)
[ "${RESTARTS:-0}" = "0" ] \
  || fail "the shop container has restarted ${RESTARTS} time(s) — with the correct fix it starts once and stays up."

# 6) /healthz must answer ok with a populated catalog.
HEALTH=$(kubectl -n "$NS" exec deploy/"$DEPLOY" -- \
  python -c 'import urllib.request; print(urllib.request.urlopen("http://127.0.0.1:8000/healthz", timeout=10).read().decode())' 2>/dev/null)
echo "$HEALTH" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"ok"' \
  || fail "GET /healthz did not report ok (got: ${HEALTH:-no response})."
ROWS=$(echo "$HEALTH" | grep -oE '"catalog_rows"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)
[ "${ROWS:-0}" -gt 0 ] \
  || fail "the catalog reports 0 rows — the elf's restock did not complete. Its initContainer must run migrate AND the catalog rebuild."

broadcast "✅ [PASS] The elf now finishes its shift (initContainer, exit 0) before the shop container starts — and the shop stays up with full shelves."
exit 0
