# Scenario Objective: The Untagged Shipment

The rogue elves deployed the Sleigh Dashboard using `python:latest` as the container image. This is extremely dangerous in production!

The `latest` tag is **mutable** — it points to a different image every time Python publishes an update. This means your deployment could silently break overnight when the base image changes, or worse, a compromised `latest` tag could inject malicious code into your cluster.

The North Pole Container Standard demands that all images use a **pinned, immutable version tag**.

## Your Task

1. Open `~/untagged-app.yaml`.
2. Change the image from `python:latest` to a specific, pinned version (e.g., `python:3.13-slim`).
3. Apply the manifest: `kubectl apply -f ~/untagged-app.yaml`
4. Click the `Check` button!
