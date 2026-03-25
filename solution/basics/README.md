# Trainee Elf Orientation - Solution Guide

## Step 1: The Elf's Typo (YAML Debugging)

### What Went Wrong
The rogue elves introduced 3 errors into `typo-app.yaml` that prevent `kubectl apply` from accepting it.

### How to Diagnose
Run `kubectl apply -f ~/typo-app.yaml` and read the error message. Kubernetes will tell you:
- The API version is wrong
- The resource kind is unknown

### The Fix

**Error 1: Wrong API Version**  
`apiVersion: app/v1` should be `apiVersion: apps/v1`. Deployments live in the `apps` API group (plural).

**Error 2: Misspelled Kind**  
`kind: Deplyoment` should be `kind: Deployment`. Kubernetes rejects unknown resource types.

**Error 3: Indentation**  
`readinessProbe` on line 27 has an extra space, making it a child of `limits` instead of a sibling of `resources`. Align it with the `resources` block.

```diff
-           readinessProbe:
+          readinessProbe:
```

### Why It Matters
YAML is whitespace-sensitive. A single extra space can change the entire structure of your manifest. Always validate with `kubectl apply --dry-run=client -f <file>` before deploying.

---

## Step 2: The Untagged Shipment (Image Pinning)

### What Went Wrong
The image is set to `python:latest`. The `latest` tag is **mutable** - it points to whatever the newest version is right now. Tomorrow, it could point to a completely different Python version.

### How to Diagnose
Open `untagged-app.yaml` and look at the `image` field. The verify script checks that the tag is NOT `latest`.

### The Fix

```diff
-          image: python:latest
+          image: python:3.13-slim
```

Any pinned version tag works (e.g., `python:3.13`, `python:3.13.2`), but `latest` will always fail the verify.

### Why It Matters
In production, mutable tags cause "works on my machine" problems. When a node pulls a newer version of `python:latest`, your app might break silently. Pinned tags ensure every deployment is reproducible.

---

## Step 3: The Lost Namespace (Namespace Scoping)

### What Went Wrong
The manifest targets `namespace: north-pole-logistics`, but that namespace doesn't exist in the cluster.

### How to Diagnose
`kubectl apply -f ~/namespace-app.yaml` returns: `Error: namespaces "north-pole-logistics" not found`

### The Fix

```bash
kubectl create namespace north-pole-logistics
kubectl apply -f ~/namespace-app.yaml
```

### Why It Matters
Namespaces provide resource isolation in Kubernetes. In production, namespaces are often pre-created by cluster admins or IaC tools. If your deployment targets a namespace that doesn't exist, Kubernetes rejects it immediately. Always verify your target namespace exists before deploying.
