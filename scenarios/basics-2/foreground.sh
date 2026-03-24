#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

while ! kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done
clear
broadcast "🎄 Welcome to the Trainee Elf OJT!"
broadcast "You have 3 deployments to debug:"
broadcast "  ~/ghost-app.yaml      - The Ghost Container (ImagePullBackOff)"
broadcast "  ~/crash-app.yaml      - The Crash Loop (CrashLoopBackOff)"
broadcast "  ~/hardcoded-app.yaml  - The Hardcoded Password (Security Fix)"
broadcast "This time, kubectl apply will succeed — but the pods won't."
broadcast "Use 'kubectl describe' and 'kubectl logs' to investigate!"
