# The Trojan Manifest - Solution Guide

This 5-step challenge introduces one cluster policy at a time. Each step adds a new security requirement. Your job is to iteratively fix `app.yaml` until it passes all policies.

---

## Step 1: Resource Boundaries (Requests & Limits)

### What the Policy Enforces
Every container must declare CPU and memory **requests** (minimum guaranteed) and **limits** (maximum allowed).

### How to Diagnose
```bash
kubectl apply -f ~/app.yaml
# Error: "CPU and memory requests and limits are required."
```

### The Fix
Add a `resources` block to the container spec:

```yaml
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
```

### Why It Matters
Without resource limits, a single runaway container can consume all CPU/memory on a node, starving every other workload (known as the "noisy neighbor" problem). `requests` guarantee minimum resources; `limits` cap maximum consumption.

- **`100m` CPU** = 0.1 cores (100 millicores)
- **`128Mi` memory** = 128 mebibytes

---

## Step 2: Health Probes (Liveness & Readiness)

### What the Policy Enforces
Every container must have `livenessProbe` and `readinessProbe` using `httpGet`.

### How to Diagnose
```bash
kubectl apply -f ~/app.yaml
# Error: "Liveness and readiness probes with httpGet are required."
```

### The Fix
Add both probes to the container spec:

```yaml
          livenessProbe:
            httpGet:
              path: /
              port: 8000
            initialDelaySeconds: 5
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /
              port: 8000
            initialDelaySeconds: 5
            periodSeconds: 5
```

### Why It Matters
- **Liveness probe**: "Is the container still alive?" If it fails, Kubernetes **restarts** the container. Catches deadlocks and frozen processes.
- **Readiness probe**: "Is the container ready to serve traffic?" If it fails, Kubernetes **removes it from the Service** so no traffic is routed to it. Useful for startup warmup or temporary overload.

Without probes, Kubernetes assumes a running container is always healthy, which can route traffic to broken instances.

---

## Step 3: Standard Labels

### What the Policy Enforces
Pod templates must include `app.kubernetes.io/name` and `app.kubernetes.io/instance` labels.

### How to Diagnose
```bash
kubectl apply -f ~/app.yaml
# Error: "The label 'app.kubernetes.io/name' is required."
```

### The Fix
Add the required labels to `template.metadata.labels` (NOT the top-level `metadata.labels`):

```yaml
  template:
    metadata:
      labels:
        app: sleigh-telemetry
        app.kubernetes.io/name: "gift-tracking-app"
        app.kubernetes.io/instance: "gift-tracking-app"
```

### Why It Matters
The `app.kubernetes.io/*` labels are the [Kubernetes Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/) standard. They allow monitoring dashboards (Grafana), service meshes (Istio), and GitOps tools (ArgoCD) to automatically discover and group related resources. Without them, your workloads are invisible to enterprise tooling.

---

## Step 4: Service Account Isolation

### What the Policy Enforces
Pods must NOT use the `default` service account. A dedicated ServiceAccount must be configured.

### How to Diagnose
```bash
kubectl apply -f ~/app.yaml
# Error: "Using the 'default' service account is not allowed."
```

### The Fix

**1. Create a dedicated ServiceAccount:**
```bash
kubectl create sa gift-tracking-sa
```

**2. Reference it in the pod spec:**
```yaml
    spec:
      serviceAccountName: gift-tracking-sa
```

### Bonus: Disable Token Automount

By default, Kubernetes mounts an API token into every pod. If the app doesn't need to talk to the Kubernetes API, disable it:

```yaml
      automountServiceAccountToken: false
```

### Why It Matters
The `default` service account often has more permissions than necessary. If an attacker compromises a container using the default SA, they may be able to list pods, read secrets, or escalate privileges. A dedicated SA with minimal RBAC permissions follows the **principle of least privilege**.

---

## Step 5: Container Security Context (Non-Root)

### What the Policy Enforces
Containers must run as a non-root user (`runAsNonRoot: true`).

### How to Diagnose
```bash
kubectl apply -f ~/app.yaml
# Error: "Running containers as root is not allowed. Set securityContext.runAsNonRoot to true."
```

### The Fix
Add a `securityContext` to the container spec:

```yaml
          securityContext:
            runAsNonRoot: true
```

### Bonus: Drop All Capabilities

Linux capabilities are fine-grained root powers. Drop them all unless specifically needed:

```yaml
          securityContext:
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
```

### Why It Matters
Running as root inside a container is the single biggest security risk in Kubernetes:
- Root can modify any file in the container filesystem
- Container breakout vulnerabilities (e.g., CVE-2019-5736) allow root-in-container to become root-on-host
- Root can bind to privileged ports and access sensitive `/proc` and `/sys` paths

`runAsNonRoot: true` tells the kubelet to **refuse to start** any container whose image defaults to UID 0. The `capabilities.drop: [ALL]` removes Linux capabilities like `NET_RAW`, `SYS_ADMIN`, etc., which are often exploited for privilege escalation.
