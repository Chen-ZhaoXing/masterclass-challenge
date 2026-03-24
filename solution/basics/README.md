# Trainee Elf Orientation - Solutions

## Step 1: The Elf's Typo

The broken `typo-app.yaml` has 3 errors:

1. **`apiVersion: app/v1`** → Should be **`apps/v1`**
2. **`containerPort: "8080"`** → Should be integer **`containerPort: 8080`** (no quotes)
3. **`readinessProbe` indentation** → Misaligned by 1 extra space, needs to match `resources` indentation

## Step 2: The Untagged Shipment

Change the image tag from the mutable `python:latest` to a pinned version:

```diff
-          image: python:latest
+          image: python:3.13-slim
```

## Step 3: The Lost Namespace

Create the missing namespace, then re-apply:

```bash
kubectl create namespace north-pole-logistics
kubectl apply -f ~/namespace-app.yaml
```
