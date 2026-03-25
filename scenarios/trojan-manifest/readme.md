# The Trojan Manifest

| | |
|---|---|
| **Difficulty** | 🔴 Advanced |
| **Points** | 300 |
| **Steps** | 5 |
| **Prerequisites** | Kubernetes deployment manifests, security contexts, basic understanding of admission controllers |
| **Learning Objectives** | Policy enforcement, resource requests/limits, health probes, standard labeling, ServiceAccount isolation, container security context |

## Overview

A bare-bones deployment manifest (`app.yaml`) must pass 5 increasingly strict cluster policies enforced by a Kubernetes policy engine (Kyverno). Each step introduces one new policy, and students iteratively harden the manifest until it passes all admission checks.

## Steps

| Step | Title | Policy Enforced |
|------|-------|----------------|
| 1 | Resource Boundaries | `require-resource-limits` - CPU and memory requests/limits required |
| 2 | Health Probes | `require-http-probes` - Liveness and readiness probes with `httpGet` |
| 3 | Standard Labels | `require-labels` - `app.kubernetes.io/name` and `app.kubernetes.io/instance` |
| 4 | Service Account Isolation | `require-non-default-sa` - Must not use the `default` ServiceAccount |
| 5 | Non-Root Execution | `require-non-root` - `securityContext.runAsNonRoot: true` |

### Bonus Challenges
- **Step 4 Bonus:** Disable `automountServiceAccountToken`
- **Step 5 Bonus:** Drop all Linux capabilities (`capabilities.drop: [ALL]`)

## Files

- `assets/app.yaml` - The initial insecure manifest (starting point)
- `assets/kyverno-policies/` - All 6 Kyverno ClusterPolicy YAML files
- `background.sh` - Installs Helm, Kyverno, creates namespace, sets context
- `step{1-5}/verify.sh` - Per-step verification (uses `--dry-run=server`)
- `step{1-5}/background.sh` - Per-step policy application
- `step{1-5}/readme.md` - Per-step instructions

## Environment Setup

The main `background.sh`:
1. Installs Helm
2. Deploys Kyverno via Helm chart
3. Waits for admission controller readiness
4. Creates `gift-tracking` namespace and sets it as default context
5. Waits 60s for webhook registration

Each step's `background.sh` applies the next policy.

## Verification Notes

- All verify scripts use `kubectl delete clusterpolicies --all` then apply ONLY the current step's policy before checking
- Uses `--dry-run=server` to validate without creating live resources
- Step 4 has additional `grep` checks for `serviceAccountName` in the manifest (with `tr -d '\r'` for Windows line endings in app.yaml)
- Step 5 always prints the flag on non-root pass, regardless of bonus result