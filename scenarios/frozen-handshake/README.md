# The Frozen Handshake

| | |
|---|---|
| **Difficulty** | 🟡 Intermediate |
| **Points** | 100 |
| **Steps** | 1 |
| **Prerequisites** | Basic Kubernetes (Deployments, Services, Secrets), basic Helm templating |
| **Learning Objectives** | TLS trust chains, CA certificate distribution, Secret volume mounts, runtime verification |

## Overview

A telemetry client needs to communicate with a TLS-enabled internal service, but the CA certificate is missing from the client pod. Students must mount the CA cert from an existing Secret and configure the application to use it for TLS verification.

## Steps

| Step | Title | Skill Tested |
|------|-------|-------------|
| 1 | Restore the Trust Chain | Mount CA cert from Secret, set `TLS_CERT_PATH` env var |

## Files

- `foreground.sh` - Setup script that deploys the TLS echo server and client chart
- `verify.sh` - Checks that the CA cert is mounted and the TLS handshake succeeds

## Verification Notes

- Verifies the `northpole-ca` Secret is mounted as a volume
- Checks that `TLS_CERT_PATH` environment variable points to the mounted cert
- Confirms the client pod is Running (no more TLS handshake failures)
