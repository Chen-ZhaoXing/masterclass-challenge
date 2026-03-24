#!/bin/bash
# Wait for Kubernetes to be ready
until kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done
echo "Cluster is ready!"
