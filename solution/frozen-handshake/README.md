# The Frozen Handshake - Solution Guide

## The Vulnerability

The telemetry client needs to communicate with a TLS-enabled internal endpoint, but the rogue elves never mounted the Certificate Authority (CA) certificate into the client container. Without the CA cert, the client can't verify the server's identity, and the TLS handshake fails.

## How to Diagnose

```bash
# Check the pod status - it will be in CrashLoopBackOff
kubectl get pods -n challenge4

# Check the logs for the TLS error
kubectl logs <pod-name> -n challenge4
# Output: "SSL certificate problem: unable to get local issuer certificate"

# Find the CA cert Secret
kubectl get secrets -n challenge4
kubectl describe secret northpole-ca -n challenge4
# Shows key: ca.crt
```

The application expects the `TLS_CERT_PATH` environment variable to point to the CA certificate file.

## The Fix

Three changes are needed in the Helm chart's `deployment.yaml`:

### 1. Add a Volume backed by the CA Secret

```yaml
volumes:
  - name: tls-certs
    secret:
      secretName: northpole-ca
```

This makes all keys in the `northpole-ca` Secret available as files.

### 2. Mount the Volume into the container

```yaml
volumeMounts:
  - name: tls-certs
    mountPath: /etc/tls
    readOnly: true
```

The `ca.crt` key from the Secret becomes the file `/etc/tls/ca.crt`.

### 3. Set the environment variable

```yaml
env:
  - name: TLS_CERT_PATH
    value: "/etc/tls/ca.crt"
```

This tells the application where to find the CA certificate for TLS verification.

### Deploy

```bash
helm upgrade --install challenge4 ~/tls-client-chart -n challenge4
```

## Why It Matters

**TLS trust chains** are fundamental to secure communication:

- **CA Certificates** establish trust. The client needs the CA cert to verify that the server's certificate is legitimate and hasn't been forged.
- **Without CA verification**, the connection is vulnerable to man-in-the-middle attacks where an attacker could intercept and modify traffic between services.
- **In Kubernetes**, internal CAs are commonly used for service mesh communication (mTLS), webhook endpoints, and custom API servers.
- **Never skip TLS verification** (`--insecure` / `verify=False`) in production. Instead, properly distribute the CA cert via Secrets and volume mounts.
