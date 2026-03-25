# Trainee Elf Orientation

| | |
|---|---|
| **Difficulty** | 🟢 Beginner |
| **Points** | 50 |
| **Steps** | 3 |
| **Prerequisites** | Basic YAML syntax, basic `kubectl` usage |
| **Learning Objectives** | Reading Kubernetes error messages, image tag pinning, namespace scoping |

## Overview

Three sabotaged manifests that each fail at `kubectl apply` time. Each contains a single, intentional error that students must identify and fix by reading the error output.

## Steps

| Step | Title | Skill Tested |
|------|-------|-------------|
| 1 | The Elf's Typo | YAML syntax debugging (`apiVersion`, `kind` spelling, indentation) |
| 2 | The Untagged Shipment | Image tag mutability - pin `latest` to a specific version |
| 3 | The Lost Namespace | Namespace scoping - create a missing namespace before deploying |

## Files

- `assets/typo-app.yaml` - Manifest with 3 intentional YAML errors
- `assets/untagged-app.yaml` - Manifest using `python:latest` (mutable tag)
- `assets/namespace-app.yaml` - Manifest targeting a non-existent namespace
- `step{1,2,3}/verify.sh` - Verification scripts for each step
- `step{1,2,3}/readme.md` - Per-step instructions shown to students

## Verification Notes

- Step 1 checks that the `gift-tracker` deployment exists and has available replicas
- Step 2 checks that the image tag is NOT `latest`
- Step 3 checks that the namespace and deployment exist
