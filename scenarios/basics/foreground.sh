#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

# Wait for background setup to complete
while ! kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done
clear
broadcast "🎄 Welcome, Trainee Elf! The cluster is ready."
broadcast "You have 3 manifests to fix:"
broadcast "  ~/typo-app.yaml       - The Elf's Typo"
broadcast "  ~/untagged-app.yaml   - The Untagged Shipment"
broadcast "  ~/namespace-app.yaml  - The Lost Namespace"
broadcast "Good luck!"
