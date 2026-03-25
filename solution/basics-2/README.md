# Trainee Elf OJT - Solution Guide

In this scenario, all three manifests will `kubectl apply` successfully - the YAML is valid. But the pods themselves fail in different ways. You must use diagnostic tools to figure out what's wrong.

---

## Step 1: The Ghost Container (ImagePullBackOff)

### What Went Wrong
The container image name has a typo: `nignx:1.25` instead of `nginx:1.25`. Kubernetes can't pull an image that doesn't exist.

### How to Diagnose
```bash
kubectl apply -f ~/ghost-app.yaml
kubectl get pods                      # Shows "ImagePullBackOff" or "ErrImagePull"
kubectl describe pod <pod-name>       # Events section shows: Failed to pull image "nignx:1.25"
```

The Events section at the bottom of `kubectl describe` is where Kubernetes logs what's happening behind the scenes. Look for `Failed to pull image` to identify the exact problem.

### The Fix
```diff
-          image: nignx:1.25
+          image: nginx:1.25
```

### Why It Matters
`ImagePullBackOff` is one of the most common pod failures. It means Kubernetes tried to download the container image and failed. Common causes: typos in image names, missing registry credentials, or private registries without `imagePullSecrets`.

---

## Step 2: The Crash Loop (CrashLoopBackOff)

### What Went Wrong
The container starts but immediately crashes because the `command` field references `pythn` - a binary that doesn't exist inside the container.

### How to Diagnose
```bash
kubectl apply -f ~/crash-app.yaml
kubectl get pods                      # Shows "CrashLoopBackOff" or "Error"
kubectl describe deployment naughty-nice-api   # Shows the error details
```

The describe output will mention an executable that wasn't found.

### The Fix
```diff
-          command: ["pythn", "-m", "http.server", "8000"]
+          command: ["python", "-m", "http.server", "8000"]
```

### Why It Matters
`CrashLoopBackOff` means Kubernetes started the container, it exited with an error, and Kubernetes keeps restarting it (with increasing backoff delays). The `kubectl logs <pod-name>` command shows the container's stdout/stderr, which usually reveals why it crashed. Always check logs for crash loops.

---

## Step 3: The Hardcoded Password (Kubernetes Secrets)

### What Went Wrong
The deployment has `DB_PASSWORD: "NorthPole2025!"` hardcoded as a plaintext environment variable. Anyone who can `kubectl get deployment` can see the password. The verify script checks that the password is stored in a Kubernetes Secret instead.

### How to Diagnose
Open `hardcoded-app.yaml` and look for the `env` section. You'll see the password in plain text.

### The Fix

**1. Create the Secret:**
```bash
kubectl create secret generic db-credentials --from-literal=DB_PASSWORD=NorthPole2025!
```

**2. Update the manifest to reference the Secret:**
```diff
           - name: DB_PASSWORD
-              value: "NorthPole2025!"
+              valueFrom:
+                secretKeyRef:
+                  name: db-credentials
+                  key: DB_PASSWORD
```

**3. Re-apply:**
```bash
kubectl apply -f ~/hardcoded-app.yaml
```

### Why It Matters
Hardcoded secrets in manifests are a critical security risk. Manifests are stored in git repos, CI/CD logs, and etcd. Kubernetes Secrets (while base64-encoded, not encrypted by default) provide a dedicated mechanism to manage sensitive data separately from application configuration. In production, combine with external secret managers (HashiCorp Vault, AWS Secrets Manager) for true encryption at rest.
