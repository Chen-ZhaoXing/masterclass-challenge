> **Points:** 100
>
> **Prerequisites:** Basic Kubernetes (Deployments, Services, Secrets), basic Helm templating
>
> **Learning Objectives:** TLS trust chains, CA certificate distribution, Secret volume mounts, runtime verification

# The Frozen Handshake

## The Situation

The rogue elves changed one more thing before escaping: they turned on TLS for an internal endpoint, but never mounted the trusted CA certificate into the client workload.

Now the **North Pole Telemetry Client** cannot complete a secure handshake with the in-cluster HTTPS service, so it keeps crashing.

## Your Mission

A Helm chart is provided at `~/tls-client-chart/`. The deployment is almost correct, but it is missing the certificate mount.

Fix the chart so the client can validate TLS successfully and stay healthy.

### What already exists

- Namespace: `challenge4`
- HTTPS service: `tls-echo.challenge4.svc.cluster.local:8443`
- Secret containing trusted CA certificate: `northpole-ca` (file key: `ca.crt`)

### Goal

Update the client deployment to mount the CA cert from the secret and point `TLS_CERT_PATH` to the mounted file path.

When complete, the workload should run successfully and verification will pass.
