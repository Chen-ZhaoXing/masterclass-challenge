# Trainee Elf Graduation — Solution Guide

## Step 1: The Invisible App (Services)

The deployment runs fine but has no Service, so nothing can reach it.

**Fix:** Create a ClusterIP Service targeting the deployment's pod labels:

```bash
kubectl expose deployment gift-dashboard --port=80 --target-port=80
```

Or create a `service.yaml`:

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

---

## Step 2: The Missing Config (ConfigMaps)

The deployment references a ConfigMap `weather-config` that doesn't exist, causing `CreateContainerConfigError`.

**Fix:** Create the ConfigMap with the required keys:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: weather-config
data:
  APP_MODE: "production"
  LOG_LEVEL: "info"
```

```bash
kubectl create configmap weather-config --from-literal=APP_MODE=production --from-literal=LOG_LEVEL=info
```

Then re-apply the deployment if needed:

```bash
kubectl apply -f ~/noconfig-app.yaml
```

The pod will start once the ConfigMap exists with both `APP_MODE` and `LOG_LEVEL` keys.
