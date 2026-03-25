# Trainee Elf Graduation - Solution Guide

This scenario tests two foundational Kubernetes concepts: making deployments reachable (Services) and injecting configuration (ConfigMaps).

---

## Step 1: The Invisible App (Kubernetes Services)

### What Went Wrong
The `gift-dashboard` deployment is running perfectly - the pod is healthy. But in Kubernetes, a running pod is **not** automatically reachable by other pods. Pods get ephemeral IPs that change on restart. Something else is needed to provide stable networking.

### How to Diagnose
```bash
kubectl apply -f ~/invisible-app.yaml
kubectl get pods                      # Pod shows "Running" - looks fine!
kubectl get services                  # No Service exists for gift-dashboard
```

The pod works, but there's no **Service** to give it a stable DNS name and IP.

### The Fix

**Option A: One-liner**
```bash
kubectl expose deployment gift-dashboard --port=80 --target-port=80
```

**Option B: Declarative YAML**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: gift-dashboard
spec:
  selector:
    app: gift-dashboard
  ports:
    - port: 80
      targetPort: 80
```

The key is that the Service's `selector.app` must match the Deployment's `pod.labels.app` (`gift-dashboard`), and the `targetPort` must match the container's `containerPort` (80).

### Why It Matters
A **Service** provides:
- **Stable DNS**: Other pods can reach it at `gift-dashboard.default.svc.cluster.local`
- **Stable IP**: The ClusterIP doesn't change even when pods restart
- **Load balancing**: If you scale to multiple replicas, the Service distributes traffic

Without a Service, pods are invisible to the rest of the cluster. This is the most fundamental Kubernetes networking concept.

---

## Step 2: The Missing Config (ConfigMaps)

### What Went Wrong
The `weather-api` deployment references a ConfigMap called `weather-config` via `configMapKeyRef`, but that ConfigMap doesn't exist. Kubernetes can't inject the environment variables, so the container can't even start.

### How to Diagnose
```bash
kubectl apply -f ~/noconfig-app.yaml
kubectl get pods                      # Shows "CreateContainerConfigError"
kubectl describe pod <pod-name>       # Events: 'configmap "weather-config" not found'
```

The error `CreateContainerConfigError` specifically means Kubernetes failed to set up the container's environment before starting it. The Events section tells you exactly which resource is missing.

### The Fix

**Option A: One-liner**
```bash
kubectl create configmap weather-config --from-literal=APP_MODE=production --from-literal=LOG_LEVEL=info
```

**Option B: Declarative YAML**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: weather-config
data:
  APP_MODE: "production"
  LOG_LEVEL: "info"
```

Once the ConfigMap exists, Kubernetes will automatically retry creating the container. The pod should transition to `Running` within seconds.

### Why It Matters
**ConfigMaps** decouple configuration from container images. Instead of baking `APP_MODE=production` into a Dockerfile, you provide it at deploy time. This means:
- The same image works in dev, staging, and production
- You can change config without rebuilding the image
- Configuration is visible and auditable via `kubectl get configmap`

ConfigMaps are for non-sensitive configuration. For passwords and tokens, use **Secrets** instead (covered in OJT Step 3).
