# The Bloated Sleigh Image

| | |
|---|---|
| **Difficulty** | 🟡 Intermediate |
| **Points** | 200 |
| **Steps** | 1 |
| **Prerequisites** | Basic Docker/Dockerfile knowledge, understanding of container images and layers |
| **Learning Objectives** | Multi-stage builds, slim base images, non-root execution, layer caching, OCI labels, `HEALTHCHECK` |

## Overview

The Sleigh Telemetry Service has a Dockerfile producing a 1GB+ image running as root. Students must rewrite it using production best practices: multi-stage builds, slim base images, non-root user, caching optimization, and metadata.

## Steps

| Step | Title | Skill Tested |
|------|-------|-------------|
| 1 | Rewrite the Dockerfile | Multi-stage build, `python:3.13-slim`, `USER 1001:0`, `HEALTHCHECK`, OCI labels |

## Files

- `assets/bloated-app/` - The FastAPI application source code and the broken Dockerfile
- `background.sh` - Deploys an in-cluster Docker registry at `localhost:30500`, configures insecure registry trust, pre-pulls base images
- `verify.sh` - Checks image size, non-root user, and app health

## Environment Setup

The background script:
1. Installs Docker CLI if missing
2. Deploys a registry Deployment + NodePort Service in the `registry` namespace
3. Configures containerd and Docker to trust `localhost:30500` as an insecure registry
4. Pre-pulls `python:3.13` and `python:3.13-slim` to speed up builds
5. Adds `alias podman=docker` to `.bashrc`

## Verification Notes

- Checks the pushed image at `localhost:30500/sleigh-telemetry:latest` is under 250MB
- Verifies the container does NOT run as root (UID != 0)
- Confirms the application responds on its HTTP endpoint
