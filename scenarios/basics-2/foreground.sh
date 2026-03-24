#!/bin/bash
echo "⏳ Waiting for the cluster to initialize..."
while ! kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done
clear
echo "🎄 Welcome to the Trainee Elf OJT!"
echo ""
echo "You have 3 deployments to debug:"
echo "  ~/ghost-app.yaml      - The Ghost Container (ImagePullBackOff)"
echo "  ~/crash-app.yaml      - The Crash Loop (CrashLoopBackOff)"
echo "  ~/hardcoded-app.yaml  - The Hardcoded Password (Security Fix)"
echo ""
echo "This time, kubectl apply will succeed — but the pods won't."
echo "Use 'kubectl describe' and 'kubectl logs' to investigate!"
