#!/bin/bash
# Wait for background setup to complete
echo "⏳ Waiting for the cluster to initialize..."
while ! kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done
clear
echo "🎄 Welcome, Trainee Elf! The cluster is ready."
echo ""
echo "You have 3 manifests to fix:"
echo "  ~/typo-app.yaml       - The Elf's Typo"
echo "  ~/untagged-app.yaml   - The Untagged Shipment"
echo "  ~/namespace-app.yaml  - The Lost Namespace"
echo ""
echo "Good luck!"
