# Trainee Elf OJT - Solutions

## Step 1: The Ghost Container

The image name has a typo: `nignx:1.25` → should be `nginx:1.25`.

```diff
-          image: nignx:1.25
+          image: nginx:1.25
```

**How to diagnose:** `kubectl describe pod <name>` → Events section shows `Failed to pull image "nignx:1.25"`

## Step 2: The Crash Loop

The command has a typo: `pythn` → should be `python`.

```diff
-          command: ["pythn", "-m", "http.server", "8000"]
+          command: ["python", "-m", "http.server", "8000"]
```

**How to diagnose:** `kubectl logs <pod-name>` → Shows `exec: "pythn": executable file not found in $PATH`

## Step 3: The Hardcoded Password

1. Create the Secret:
```bash
kubectl create secret generic db-credentials --from-literal=DB_PASSWORD=NorthPole2025!
```

2. Replace the hardcoded env value:
```diff
           - name: DB_PASSWORD
-              value: "NorthPole2025!"
+              valueFrom:
+                secretKeyRef:
+                  name: db-credentials
+                  key: DB_PASSWORD
```
