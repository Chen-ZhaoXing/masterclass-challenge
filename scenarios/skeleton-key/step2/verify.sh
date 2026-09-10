#!/bin/bash

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

# A failed setup is an environment problem, not the player's; say so before grading.
if [ -f /tmp/setup-failed ]; then
    broadcast "⚠️  The environment did not finish setting up: $(cat /tmp/setup-failed)"
    broadcast "   This is not something you did. Restart the scenario, and tell the facilitator if it happens again."
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

allow() {
    if ! allowed "$1" "$2" "${3:-}"; then
        broadcast "❌ [FAIL] The workload identity cannot '$1 $2' in namespace '$3'. It needs this to run."
        exit 1
    fi
}

deny() {
    if allowed "$1" "$2" "${3:-}"; then
        if [ -n "${3:-}" ]; then
            broadcast "❌ [FAIL] The workload identity can '$1 $2' in namespace '$3'. That exceeds what it needs."
        else
            broadcast "❌ [FAIL] The workload identity can '$1 $2' at cluster scope. That exceeds what it needs."
        fi
        exit 1
    fi
}

if ! kubectl get serviceaccount gift-tracking-sa -n gift-tracking >/dev/null 2>&1; then
    broadcast "❌ [FAIL] The gift-tracking workload no longer has an identity in the cluster."
    exit 1
fi

AVAILABLE=$(kubectl get deployment gift-tracker -n gift-tracking -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$AVAILABLE" ] || [ "$AVAILABLE" -lt 1 ]; then
    broadcast "❌ [FAIL] The gift-tracking application is not running."
    exit 1
fi

allow "get" "configmaps" "gift-tracking"
allow "list" "configmaps" "gift-tracking"
allow "watch" "configmaps" "gift-tracking"

deny "*" "*"
deny "create" "configmaps" "gift-tracking"
deny "update" "configmaps" "gift-tracking"
deny "delete" "configmaps" "gift-tracking"
deny "get" "secrets" "gift-tracking"
deny "list" "secrets" "gift-tracking"
deny "create" "pods" "gift-tracking"
deny "delete" "pods" "gift-tracking"
deny "get" "configmaps" "default"
deny "get" "configmaps" "kube-system"
deny "list" "configmaps" "kube-system"
deny "create" "clusterrolebindings"
deny "delete" "nodes"

broadcast "✅ [PASS] Least privilege achieved. The workload can read its own configuration and nothing else. The North Pole is secure."
exit 0
