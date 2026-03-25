# The Exposed Coordinates - Solution Guide

## The Vulnerability

The Sleigh Routing API has `APP_TOKEN` defined as a **plaintext environment variable** in the Helm deployment template. This is dangerous because:

- Anyone with `kubectl describe pod` access can see the token
- The token appears in container process trees (`/proc/1/environ`)
- Crash dumps and logging systems may capture environment variables
- The token is stored in plaintext in etcd (Kubernetes API server backing store)

## How to Diagnose

```bash
# See the secret exists in the cluster
kubectl get secrets -n challenge1

# Inspect the secret's keys
kubectl describe secret <secret-name> -n challenge1

# Look at the current deployment template for the plaintext env var
cat ~/exposed-coordinates-chart/templates/deployment.yaml
```

The deployment template has a `TODO` comment telling you where the volume mount should go.

## The Fix

Three changes are needed in the Helm chart's `deployment.yaml`:

### 1. Add a Volume backed by the Secret

```yaml
volumes:
  - name: token-volume
    secret:
      secretName: masterclass-auth
      items:
        - key: legacy-sys-token
          path: credentials.key
```

This maps the Secret key `legacy-sys-token` to a file named `credentials.key` inside the volume.

### 2. Mount the Volume into the container

```yaml
volumeMounts:
  - name: token-volume
    mountPath: /app/token
    readOnly: true
```

The `readOnly: true` flag prevents the application from accidentally modifying the secret file.

### 3. Update the environment variable

```diff
-            - name: APP_TOKEN
-              value: "<plaintext-token>"
+            - name: APP_TOKEN_PATH
+              value: "/app/token/credentials.key"
```

Instead of injecting the secret as a value, tell the app where to **read** it from the filesystem.

### Deploy

```bash
helm upgrade --install challenge1 ~/exposed-coordinates-chart -n challenge1
```

## Why It Matters

Volume-mounted secrets are significantly more secure than environment variables:
- They're stored in **tmpfs** (memory-only filesystem), never written to disk
- They don't appear in `kubectl describe pod` output
- They're not captured in crash dumps or process trees
- They can be marked `readOnly` to prevent tampering
- Kubernetes automatically updates them when the Secret changes
