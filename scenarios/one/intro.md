![Security alert banner showing a breach detection warning for the Sleigh Routing API](../assets/banner.svg)

# Challenge 1: The Rogue Elf Faction and The Exposed Coordinates

## The Situation

Tensions are high at the North Pole. A rogue faction of elves is attempting to sabotage the holiday season by hijacking the sleigh's automated routing system.

During a recent security audit, the Chief Holiday Officer discovered a critical vulnerability: the Sleigh Routing API deployed in our Kubernetes cluster is reading the Master Guidance Coordinates from a plaintext environment variable (`APP_TOKEN`). The rogue elves are actively scraping process trees and container logs to steal this token.

## The Mitigation

To stop the leak, the Elven Engineering Team has updated the source code and rebuilt the container image. The application will no longer read from `APP_TOKEN`. Instead, it now expects the secret to be securely mounted as a file, and it will locate that file using a new environment variable: `APP_TOKEN_PATH`.

Your role as Senior Security Elf is to update the cluster's deployment configuration so the coordinates are mounted securely and the application is pointed to the new file.

## Technical Resources

- **The Helm Chart:** Located at `~/masterclass-fastapi-app/`
- **The Secret:** The coordinates already exist in the cluster inside a Kubernetes Secret named `masterclass-auth` in the `challenge1` namespace.
- **The Data Key:** Inside that Secret, the token is stored under the key `legacy-sys-token`.

Use these commands to inspect the cluster and confirm what is available:

```bash
# List secrets in the namespace
kubectl get secrets -n challenge1

# Inspect a secret's keys
kubectl describe secret masterclass-auth -n challenge1

# Check application logs for errors
kubectl logs -l app.kubernetes.io/name=masterclass-fastapi-app -n challenge1
```

## Requirements for Validation

To pass the Elf Validation Script, your Helm chart must meet the following exact specifications:

1. **File name:** The secret must be mounted as a file named exactly `credentials.key` (the extension is required).
2. **Environment variable:** You must set `APP_TOKEN_PATH` in the container's environment.
3. **Value:** `APP_TOKEN_PATH` must contain the absolute path to `credentials.key` at whatever mount path you choose (for example `/etc/secrets/credentials.key`).
4. **No plaintext exposure:** The `APP_TOKEN` environment variable must not appear in the deployment.

Edit the Helm chart templates, then redeploy your release:

```bash
helm upgrade challenge1 ~/masterclass-fastapi-app -n challenge1
```

Save the holiday season, Security Elf. The Chief Holiday Officer is watching.








