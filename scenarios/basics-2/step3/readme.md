# Scenario Objective: The Hardcoded Password

The rogue elves left the worst kind of security hole: a database password hardcoded directly in a Deployment manifest!

```yaml
env:
  - name: DB_PASSWORD
    value: "NorthPole2025!"
```

This is a critical vulnerability. Anyone with access to the manifest (or `kubectl get deployment -o yaml`) can read the password in plaintext. In production, secrets should **never** appear directly in manifests - they must be stored in Kubernetes **Secrets** and referenced using `secretKeyRef`.

## Your Task

1. Create a Kubernetes Secret containing the database password:
   ```bash
   kubectl create secret generic db-credentials --from-literal=DB_PASSWORD=NorthPole2025!
   ```
2. Open `~/hardcoded-app.yaml` and replace the hardcoded `value` with a `secretKeyRef`:
   ```yaml
   env:
     - name: DB_PASSWORD
       valueFrom:
         secretKeyRef:
           name: db-credentials
           key: DB_PASSWORD
   ```
3. Apply the updated manifest: `kubectl apply -f ~/hardcoded-app.yaml`{{exec}}
4. Click the `Check` button!
