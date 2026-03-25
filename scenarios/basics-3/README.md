# Trainee Elf Graduation

| | |
|---|---|
| **Difficulty** | 🟢 Beginner |
| **Points** | 50 |
| **Steps** | 2 |
| **Prerequisites** | Completed Trainee Elf OJT, basic `kubectl` commands |
| **Learning Objectives** | Kubernetes Services (ClusterIP), ConfigMaps, environment variable injection, internal DNS |

## Overview

Two deployments where the pods themselves are fine, but the infrastructure around them is broken. Students must create supporting Kubernetes resources (Service, ConfigMap) to make the applications functional.

## Steps

| Step | Title | Skill Tested |
|------|-------|-------------|
| 1 | The Invisible App | Creating a Service to expose a Deployment inside the cluster |
| 2 | The Missing Config | Creating a ConfigMap to provide required environment variables |

## Files

- `assets/invisible-app.yaml` - Deployment with no Service (pod runs but is unreachable)
- `assets/noconfig-app.yaml` - Deployment referencing a non-existent ConfigMap
- `step{1,2}/verify.sh` - Verification scripts for each step
- `step{1,2}/readme.md` - Per-step instructions shown to students

## Verification Notes

- Step 1 dynamically discovers any Service targeting the deployment's pods and verifies DNS resolution via a temporary `dns-test` pod (cleaned up automatically)
- Step 2 checks that ConfigMap `weather-config` exists with keys `APP_MODE` and `LOG_LEVEL`, and that the pod is `Running`
