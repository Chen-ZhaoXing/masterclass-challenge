## Jam 1

The development team has updated the application to read its authentication token from a **file** rather than directly from an environment variable. This change aligns with Kubernetes security best practices around secret handling.

The updated container image has been deployed, but the Helm chart has **not** been updated to match the new application behaviour — causing the token endpoint to fail.

### Your Task

Update the Helm chart at `~/masterclass-fastapi-app/` so the application can securely access its authentication token.

- The application uses the `APP_TOKEN_PATH` environment variable to locate the token file
- The token file **must** be named `credentials.key`
- A Secret containing the token has already been provisioned for you in the `challenge1` namespace

**Investigate the cluster to find what you need:**

```bash
# Check what secrets exist
kubectl get secrets -n challenge1

# Inspect a secret's keys
kubectl describe secret <secret-name> -n challenge1

# Check the application logs
kubectl logs -l app.kubernetes.io/name=masterclass-fastapi-app -n challenge1
```






