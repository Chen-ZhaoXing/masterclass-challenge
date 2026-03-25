# The Phantom Storage

| | |
|---|---|
| **Difficulty** | 🔴 Advanced |
| **Points** | 300 |
| **Steps** | 2 |
| **Prerequisites** | Kubernetes storage concepts (PV, PVC, StorageClass), basic networking (Services), StatefulSets |
| **Learning Objectives** | PersistentVolumeClaims, StorageClasses, Access Modes, VolumeMounts, internal Kubernetes Services |

## Overview

The rogue elves wiped all storage and network configurations from a MongoDB + gift-tracker stack. Students must restore the StatefulSet's volume claim templates, create PVCs, mount backup volumes, and reconnect internal Services.

## Steps

| Step | Title | Skill Tested |
|------|-------|-------------|
| 1 | Secure the Database | Add `volumeClaimTemplates` to the StatefulSet with correct `accessModes` and `storageClassName` |
| 2 | Restore the Application | Create a PVC for backups, mount it in the Deployment, create a headless Service for MongoDB connectivity |

## Files

- `assets/statefulset.yaml` - MongoDB StatefulSet missing `volumeClaimTemplates`
- `assets/config.yaml` - ConfigMap and Secret for the application
- `assets/local-path-storage.yaml` - Rancher local-path StorageClass provisioner
- `foreground.sh` - Setup script that installs local-path provisioner and creates resources
- `step{1,2}/verify.sh` - Per-step verification scripts
- `step{1,2}/readme.md` - Per-step instructions

## Environment Setup

The `foreground.sh`:
1. Applies the local-path StorageClass provisioner
2. Creates ConfigMap and Secret resources
3. Copies manifests to the student's home directory

## Verification Notes

- Step 1 checks that `accessModes` contains `ReadWriteOnce` and `storageClassName` contains `local-path` in the applied StatefulSet's volumeClaimTemplates
- Step 2 checks for the existence of a `mongodb-service` Service, a `backup-pvc` PVC, and that the gift-tracker Deployment has the PVC mounted correctly
