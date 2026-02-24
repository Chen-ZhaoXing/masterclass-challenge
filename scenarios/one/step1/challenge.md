## 🕵️ Operation: Secure Vault

> *"We've intercepted a critical threat. The auth token is leaking through environment variables — any process on the node can read it. You have one hour to fix the deployment before the auditors arrive."*
> — Commander Kube, Head of Platform Security

---

Your squad's latest intelligence app has been deployed to OpenShift… but the Security Council has flagged it: **the auth token is being passed as a plain environment variable**, which means it's visible in pod descriptions, container logs, and process listings. 😱

The dev team already did their part — they refactored the app to **read the token from a file path** (via an env var called `APP_TOKEN_PATH`) instead of reading `APP_TOKEN` directly.

Your mission: **update the Helm chart** so the token is securely injected as a mounted file from a Kubernetes Secret.

---

### 🎯 Mission Objectives

- The token file **must** be named `credentials.key`
- The deployment **must not** expose `APP_TOKEN` as a plain env var
- The secret is already stored in a Kubernetes Secret inside the `challenge1` namespace — **find it yourself**
- Set `APP_TOKEN_PATH` to point to the exact file path of `credentials.key` inside the container

---

### 🔍 Intel Gathering

Use these commands to gather your intel from the cluster:

```bash
# What secrets are available in the namespace?
kubectl get secrets -n challenge1

# What keys does the secret hold?
kubectl describe secret <secret-name> -n challenge1

# Is the app crashing? Check the logs
kubectl logs -l app.kubernetes.io/name=masterclass-fastapi-app -n challenge1
```

Once you've gathered your intel, edit the Helm chart at `~/masterclass-fastapi-app/` and redeploy with:

```bash
helm upgrade challenge1 ~/masterclass-fastapi-app -n challenge1
```

Good luck, Agent. The auditors are watching. 🔐







