# Trainee Elf OJT

| | |
|---|---|
| **Difficulty** | 🟢 Beginner |
| **Points** | 50 |
| **Steps** | 3 |
| **Prerequisites** | Completed Trainee Elf Orientation, basic `kubectl` commands |
| **Learning Objectives** | Diagnosing `ImagePullBackOff`, debugging `CrashLoopBackOff`, Kubernetes Secrets management |

## Overview

Three deployments that `kubectl apply` successfully but whose pods fail in different ways. Students must use `kubectl describe`, `kubectl logs`, and `kubectl get` to diagnose runtime failures.

## Steps

| Step | Title | Skill Tested |
|------|-------|-------------|
| 1 | The Ghost Container | Diagnosing `ImagePullBackOff` from a typo in the image name |
| 2 | The Crash Loop | Debugging `CrashLoopBackOff` from an invalid container command |
| 3 | The Hardcoded Password | Extracting a plaintext password into a Kubernetes Secret |

## Files

- `assets/ghost-app.yaml` - Manifest with a typo in the image name (`nignx`)
- `assets/crash-app.yaml` - Manifest with a typo in the command (`pythn`)
- `assets/hardcoded-app.yaml` - Manifest with a hardcoded `DB_PASSWORD` env var
- `step{1,2,3}/verify.sh` - Verification scripts for each step
- `step{1,2,3}/readme.md` - Per-step instructions shown to students

## Verification Notes

- Step 1 checks the pod is `Running` (image pull succeeded)
- Step 2 checks the pod is `Running` (no more crash loops)
- Step 3 checks that a Secret `db-credentials` exists and the deployment references it via `secretKeyRef`
