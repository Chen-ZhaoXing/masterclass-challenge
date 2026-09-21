#!/bin/bash
printf %s "2026-09-21-r4" > /tmp/scenario-build
# Killercoda runs this the moment the step opens, concurrently with the
# scenario's own background.sh. Signalling readiness here released the
# student while Kyverno was still installing, so the sentinel is now owned
# solely by the scenario background.sh. Wait for it before touching any
# policy: before Kyverno is installed the ClusterPolicy CRD does not exist
# and every apply below would fail silently.
for _ in $(seq 1 180); do
    [ -f /tmp/setup-finished ] && break
    sleep 2
done

for _ in 1 2 3 4 5; do
    kubectl apply -f /var/kyverno-policies/require-resource-limits.yaml && break
    sleep 2
done
