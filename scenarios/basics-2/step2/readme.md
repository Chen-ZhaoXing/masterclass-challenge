# Scenario Objective: The Crash Loop

You've applied `crash-app.yaml` and the pod was created... but it keeps restarting! Check the pod status and you'll see `CrashLoopBackOff`.

This means the container starts, crashes immediately, and Kubernetes keeps trying to restart it (with increasing backoff delays). The application inside the container is failing on startup.

## Your Task

1. Apply the manifest: `kubectl apply -f ~/crash-app.yaml`{{exec}}
2. Check the pod status: `kubectl get pods`{{exec}} — you'll see `CrashLoopBackOff` or `Error`.
3. Read the container logs: `kubectl logs <pod-name>`
4. The logs will tell you exactly what command failed and why.
5. Fix the command in `crash-app.yaml`, re-apply, and wait for the pod to become `Running`.
6. Click the `Check` button!

> **Hint:** The error message in the logs will mention an executable that wasn't found. Look at the `command` field very carefully.
