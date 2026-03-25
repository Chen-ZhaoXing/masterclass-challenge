# The Exposed Coordinates

| | |
|---|---|
| **Difficulty** | 🟡 Intermediate |
| **Points** | 100 |
| **Steps** | 1 |
| **Prerequisites** | Basic Kubernetes (Pods, Deployments, Secrets), basic Helm usage |
| **Learning Objectives** | Kubernetes Secrets management, volume mounts, minimizing secret blast radius |

## Overview

The Sleigh Routing API has its authentication token exposed as a plaintext environment variable. Students must update the Helm chart to mount the existing Secret as a volume instead, following the principle of least exposure.

## Steps

| Step | Title | Skill Tested |
|------|-------|-------------|
| 1 | Secure the Coordinates | Mount a Secret as a volume, update env vars to reference the file path |

## Files

- `foreground.sh` - Setup script that deploys the Helm chart and cluster resources
- `verify.sh` - Checks that the Secret is volume-mounted (not env-injected), readOnly, and the app is healthy

## Verification Notes

- Checks that `APP_TOKEN` is NOT present as a plaintext env var
- Verifies a volume backed by the Secret exists with `readOnly: true`
- Confirms the pod is Running and the Helm release is deployed
