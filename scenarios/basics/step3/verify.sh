#!/bin/bash

broadcast() {
    for pts in /dev/pts/[0-9]*; do
        if [ -w "$pts" ]; then
            echo -e "\n$1\n" > "$pts" 2>/dev/null
        fi
    done
}

# Check if the namespace exists
kubectl get namespace north-pole-logistics >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The namespace 'north-pole-logistics' does not exist. Create it with: kubectl create namespace north-pole-logistics"
    exit 1
else
    broadcast "✅ Namespace 'north-pole-logistics' exists!"
fi

# Check if the deployment exists in the correct namespace
kubectl get deployment parcel-sorter -n north-pole-logistics >/dev/null 2>&1
if [ $? -ne 0 ]; then
    broadcast "❌ The 'parcel-sorter' deployment does not exist in the 'north-pole-logistics' namespace. Did you re-apply the manifest?"
    exit 1
else
    broadcast "✅ The 'parcel-sorter' deployment is running in 'north-pole-logistics'!"
fi

broadcast "✅ The Lost Namespace has been found! Well done, Trainee Elf!"
exit 0
