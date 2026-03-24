# Scenario Objective: The Missing Config

The rogue elves deployed the **Weather API** but it won't start! The pod is stuck and the container can't even be created.

If you check the pod status, you'll see something like `CreateContainerConfigError`. This means Kubernetes is trying to inject configuration into the container but it can't find the source.

The deployment manifest references external configuration that doesn't exist in the cluster yet. Your job is to provide it.

## Your Task

1. Apply the manifest: `kubectl apply -f ~/noconfig-app.yaml`
2. Check the pod status: `kubectl get pods`
3. Investigate the error: `kubectl describe pod <pod-name>`
4. Read the **Events** section — it tells you exactly what's missing.
5. Look at `noconfig-app.yaml` to understand what configuration the app expects.
6. Create the missing resource and wait for the pod to become `Running`. Use the name `weather-config`.
7. Click the `Check` button!

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
