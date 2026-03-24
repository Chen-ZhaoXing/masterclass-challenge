# Scenario Objective: The Lost Namespace

The rogue elves deployed the Parcel Sorter application into a namespace called `north-pole-logistics`. But they never actually created the namespace first!

When you try to apply the manifest, Kubernetes will reject it because it can't find the target namespace. This is a common production mistake — especially when deploying across multiple environments where namespace creation is handled separately.

## Your Task

1. Try applying the manifest: `kubectl apply -f ~/namespace-app.yaml`
2. Read the error message — it tells you exactly what's missing.
3. Create the missing namespace.
4. Re-apply the manifest.
5. Click the `Check` button!
