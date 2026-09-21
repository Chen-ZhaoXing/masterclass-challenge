# Scenario Objective: The Missing Config

The rogue elves deployed the **Weather API** but it won't start! The pod is stuck and the container can't even be created.

If you check the pod status, you'll see something like `CreateContainerConfigError`. This means Kubernetes is trying to inject configuration into the container but it can't find the source.

The deployment manifest references external configuration that doesn't exist in the cluster yet. Your job is to provide it.

## Your Task

1. Apply the manifest: `kubectl apply -f ~/noconfig-app.yaml`{{exec}}
2. Check the pod status: `kubectl get pods`{{exec}}
3. Investigate the error: `kubectl describe pod -l app=weather-api`{{exec}}
4. Read the **Events** section - it names the exact resource that's missing.
5. Look at what the app expects: `cat ~/noconfig-app.yaml`{{exec}} - the `env` block names the **keys** it is asking for.
6. Create the missing ConfigMap: `kubectl create configmap weather-config --from-literal=APP_MODE=production --from-literal=LOG_LEVEL=info`{{exec}}
7. Wait for the pod to become `Running` - Kubernetes retries on its own, no re-apply needed: `kubectl get pods`{{exec}}
8. Click the `Check` button!

> The key **names** (`APP_MODE`, `LOG_LEVEL`) are fixed by the manifest - the container asks for them by name. The **values** are yours to choose.

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
