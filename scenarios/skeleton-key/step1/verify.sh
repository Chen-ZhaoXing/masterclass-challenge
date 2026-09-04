#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

if [ ! -f /tmp/setup-finished ]; then
    broadcast "⚠️  Environment is still being set up. Please wait..."
    exit 1
fi

SA="system:serviceaccount:gift-tracking:gift-tracking-sa"

allowed() {
    if [ -n "${3:-}" ]; then
        kubectl auth can-i "$1" "$2" --as="$SA" -n "$3" >/dev/null 2>&1
    else
        kubectl auth can-i "$1" "$2" --as="$SA" >/dev/null 2>&1
    fi
}

deny() {
    if allowed "$1" "$2" "${3:-}"; then
        if [ -n "${3:-}" ]; then
            broadcast "❌ [FAIL] The workload identity can still '$1 $2' in namespace '$3'."
        else
            broadcast "❌ [FAIL] The workload identity can still '$1 $2' at cluster scope."
        fi
        exit 1
    fi
}

if ! kubectl get serviceaccount gift-tracking-sa -n gift-tracking >/dev/null 2>&1; then
    broadcast "❌ [FAIL] The gift-tracking workload no longer has an identity in the cluster. The running application depends on it."
    exit 1
fi

AVAILABLE=$(kubectl get deployment gift-tracker -n gift-tracking -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$AVAILABLE" ] || [ "$AVAILABLE" -lt 1 ]; then
    broadcast "❌ [FAIL] The gift-tracking application is not running."
    exit 1
fi

deny "*" "*"
deny "delete" "secrets" "kube-system"
deny "get" "secrets" "gift-tracking"
deny "create" "pods" "gift-tracking"
deny "create" "clusterrolebindings"
deny "delete" "nodes"

broadcast "✅ [PASS] The skeleton key has been revoked. The identity survives and the service is still running."
exit 0
