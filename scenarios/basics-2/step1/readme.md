# Scenario Objective: The Ghost Container

You've applied `ghost-app.yaml` to the cluster and it was accepted... but something is wrong. The pod isn't starting!

Run `kubectl get pods` and you'll see the pod is stuck in a state called `ImagePullBackOff` or `ErrImagePull`. This means Kubernetes is trying to pull the container image from the registry but it can't find it.

## Your Task

1. Apply the manifest: `kubectl apply -f ~/ghost-app.yaml`{{exec}}
2. Check the pod status: `kubectl get pods`{{exec}}
3. Investigate the failure: `kubectl describe pod <pod-name>`
4. Read the **Events** section at the bottom - it tells you exactly which image failed to pull.
5. Fix the image name in `ghost-app.yaml`, re-apply, and wait for the pod to become `Running`.
6. Click the `Check` button!

> **Hint:** Look very carefully at the image name. Does that container image actually exist on Docker Hub?
