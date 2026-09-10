# Kubernetes Security Masterclass Challenges

Welcome to the **Kubernetes Security Masterclass Challenges**! This repository contains a series of interactive, hands-on scenarios designed to test and improve your Kubernetes security and operational best practices.

These challenges are hosted on [Killercoda](https://killercoda.com/), providing an interactive, browser-based Kubernetes environment where you can deploy manifests, debug issues, and secure clusters in real-time.

👉 **[Play the Challenges on Killercoda Here](https://killercoda.com/touching/course/scenarios)**

---

## 🎄 The Storyline: The Rogue Elf Faction

Tensions are high at the North Pole. A rogue faction of elves is attempting to sabotage the holiday season by hijacking the sleigh's automated routing system and deploying insecure workloads into the North Pole Kubernetes cluster. 

As the **Senior Security Elf**, it is your job to stop them. The Chief Holiday Officer is counting on you to lock down the cluster, secure the Master Guidance Coordinates, and ensure that only production-ready, strictly validated workloads are allowed to run.

---

## 🏆 Scoring Overview

Challenges are scored using **static scoring** on CTFd. A **100-point bonus** is awarded for completing all 11 challenges.

| # | Challenge | Difficulty | Points | Time | Key Topics |
|---|-----------|------------|--------|------|------------|
| 1 | Trainee Elf Orientation | 🟢 Beginner | 50 | ~10 min | YAML debugging, image pinning, namespace scoping |
| 2 | Trainee Elf OJT | 🟢 Beginner | 50 | ~10 min | `kubectl describe`, `kubectl logs`, Secrets |
| 3 | Trainee Elf Graduation | 🟢 Beginner | 50 | ~15 min | Services, ConfigMaps |
| 4 | The Poisoned Present | 🟢 Beginner | 100 | ~15 min | Trivy, Supply Chain, CVE Remediation |
| 5 | The Exposed Coordinates | 🟡 Intermediate | 100 | ~15 min | Kubernetes Secrets, Helm, Volume Mounts |
| 6 | The Frozen Handshake | 🟡 Intermediate | 100 | ~15 min | TLS trust chains, Volume Mounts, Secret certs |
| 7 | The Bloated Sleigh Image | 🟡 Intermediate | 200 | ~25 min | Dockerfile, Multi-Stage Builds, Non-Root |
| 8 | The Impatient Elf | 🟡 Intermediate | 150 | ~25 min | initContainers, Pod Startup Ordering, CrashLoopBackOff |
| 9 | The Skeleton Key | 🟡 Intermediate | 200 | ~20 min | RBAC, ServiceAccounts, Least Privilege |
| 10 | The Trojan Manifest | 🔴 Advanced | 300 | ~40 min | Security Context, Probes, Policy Enforcement |
| 11 | The Phantom Storage | 🔴 Advanced | 300 | ~30 min | PVCs, StorageClasses, Services |
| - | Completion Bonus | - | +100 | - | Complete all 11 challenges |
| | | | **1700** | **~220 min** | |

Each challenge has **layered hints** - the first hint is free, with subsequent hints costing 10–20% of the challenge points. See [CTFd-Scoring.md](CTFd-Scoring.md) for full hint definitions and CTFd configuration details.

---

## 🚀 Available Scenarios

### 🟢 Beginner Tier

#### Trainee Elf Orientation
The rogue elves left behind three sabotaged manifests during their last raid. Each one contains a simple but critical mistake that will prevent the application from deploying.
- **Challenges:** Fix a YAML typo, pin a mutable image tag, create a missing namespace.
- **Learning Objectives:** Reading Kubernetes error messages, image tag best practices, namespace scoping.

#### Trainee Elf OJT
Three more sabotaged deployments - but this time `kubectl apply` succeeds. The pods themselves fail in different ways.
- **Challenges:** Diagnose `ImagePullBackOff`, debug `CrashLoopBackOff`, extract hardcoded credentials into a Secret.
- **Learning Objectives:** `kubectl describe`, `kubectl logs`, Kubernetes Secrets management.

#### Trainee Elf Graduation
The final beginner assessment. Pods run fine, but the infrastructure around them is broken.
- **Challenges:** Expose a deployment with a Service, provide application configuration via a ConfigMap.
- **Learning Objectives:** Kubernetes Services (ClusterIP), ConfigMaps, environment variable injection.

#### The Poisoned Present
The Sleigh Telemetry Service has been small, non-root and green on the dashboard for years — so nobody rebuilt it. Its base image quietly reached end-of-life, its pinned dependencies aged past their own published patches, and the first supply-chain scan ever run against it comes back with 96 fixable HIGH/CRITICAL findings. Small and safe turn out to be different properties.
- **Your Mission:** Read the Trivy report, then make exactly two edits — the `FROM` line in the `Dockerfile` and the four stale pins in `requirements.txt` — until the scan comes back clean of fixable HIGH/CRITICAL findings.
- **Learning Objectives:** Reading a Trivy vulnerability report, fixed vs. unfixed CVEs, base image freshness vs. size, dependency-pinning hygiene (floors vs. ceilings).

---

### 🟡 Intermediate Tier

#### The Exposed Coordinates
The Sleigh Routing API is leaking the Master Guidance Coordinates through a plaintext environment variable (`APP_TOKEN`). The rogue elves are actively scraping process trees and container logs to steal this token.
- **Your Mission:** Refactor the Helm chart to securely mount the Kubernetes Secret as a file and remove the plaintext environment variable.
- **Learning Objectives:** Secrets management, `volumeMounts`, minimizing secret blast radius.

#### The Frozen Handshake
The rogue elves turned on TLS for an internal endpoint, but intentionally neglected to mount the trusted CA certificate into the client workload, causing severe connection errors.
- **Your Mission:** Update the client deployment to mount the correct CA cert from a Secret so TLS validation succeeds.
- **Learning Objectives:** TLS trust chains, CA certificate distribution, runtime verification.

#### The Bloated Sleigh Image
The rogue elves have sabotaged the container build pipeline with a 1GB+ Docker image running as root. The North Pole Container Standard demands images under 250 MB with non-root execution.
- **Your Mission:** Rewrite the Dockerfile using multi-stage builds, a slim base image, and a non-root user.
- **Learning Objectives:** Multi-stage Docker builds, image size optimization, non-root containers, layer caching.

#### The Impatient Elf
The new Gift Registry build crash-loops every time it boots: the shop opens *before* the shelves are stocked, because the restocking elf was moved out of the prep shift and now races the app as a sibling container.
- **Your Mission:** Diagnose why the Pod crash-loops (write the root cause down), then fix the Deployment so the elf's catalog rebuild is guaranteed to finish before the shop container starts.
- **Learning Objectives:** initContainers vs. regular containers, Pod startup ordering, diagnosing `CrashLoopBackOff` with `kubectl describe` / per-container logs.

#### The Skeleton Key
The gift-tracking workload was handed `cluster-admin` during a deployment window and nobody took it back. Nothing is broken, nothing is alerting, and the service runs perfectly — which is exactly why it went unnoticed until the pre-flight audit pulled the authorization records.
- **Your Mission:** Establish what the workload's identity can currently do, revoke the grant that gives it cluster-wide power without taking the service down, then grant back only what it genuinely needs: read access to ConfigMaps in its own namespace.
- **Learning Objectives:** Kubernetes RBAC, least-privilege authorization, Roles vs ClusterRoles, auditing effective permissions with `kubectl auth can-i --as`.

---

### 🔴 Advanced Tier

#### The Trojan Manifest
The rogue elves have submitted a poorly configured, exploitable manifest (`app.yaml`) to deploy a new "gift-tracking" API. The Chief Holiday Officer has deployed a Kubernetes policy engine to reject any resources that do not meet production standards.
- **Your Mission:** Attempt to deploy the manifest, debug the policy violations, and refactor the YAML to meet all security and operational requirements.
- **Learning Objectives:** Admission controllers, container security context (non-root, dropping capabilities), resource requests/limits, liveness/readiness probes, workload labeling, ServiceAccount isolation.

#### The Phantom Storage
The rogue elves completely wiped the storage boundaries and network services for the MongoDB database and frontend application, ensuring massive data loss and total deployment failure.
- **Your Mission:** Define the `storageClassName` and `accessModes`, provision a new `PersistentVolumeClaim` for offline backups, and reconnect the internal Service network.
- **Learning Objectives:** PersistentVolumeClaims, StorageClasses, Access Modes, Kubernetes Networking.

---

## 🛠 Project Structure

- `scenarios/basics/` - Trainee Elf Orientation (YAML, images, namespaces)
- `scenarios/basics-2/` - Trainee Elf OJT (diagnostics, Secrets)
- `scenarios/basics-3/` - Trainee Elf Graduation (Services, ConfigMaps)
- `scenarios/poisoned-present/` - The Poisoned Present (Trivy, supply chain, CVE remediation)
- `scenarios/exposed-coordinates/` - The Exposed Coordinates (Helm, Secrets, volume mounts)
- `scenarios/frozen-handshake/` - The Frozen Handshake (TLS, certs, volume mounts)
- `scenarios/bloated-docker-image/` - The Bloated Sleigh Image (Dockerfile, multi-stage)
- `scenarios/impatient-elf/` - The Impatient Elf (initContainers, pod startup ordering)
- `scenarios/skeleton-key/` - The Skeleton Key (RBAC, ServiceAccounts, least privilege)
- `scenarios/trojan-manifest/` - The Trojan Manifest (policy enforcement, security context)
- `scenarios/storageclass/` - The Phantom Storage (PVCs, StorageClasses, Services)
- `solution/` - Reference solutions for each challenge
- `CTFd-Scoring.md` - Full CTFd scoring configuration with point values, hint costs, and setup guide

---

## 💡 How to Run Locally

If you want to test or modify the challenges locally before pushing to Killercoda:

1. You will need a local Kubernetes cluster (e.g., Minikube, kind, or Docker Desktop).
2. For The Trojan Manifest challenge, install a policy engine such as [Kyverno](https://kyverno.io/docs/installation/) and apply the policies found in `scenarios/trojan-manifest/assets/kyverno-policies/`.
3. For The Phantom Storage challenge, ensure a local volume provisioner like `local-path-provisioner` exists.
4. For The Impatient Elf challenge, build the two app images from `gift-registry-app/` (`make docker`, or the build steps in `scenarios/impatient-elf/local-test/test.sh`) and load them into your cluster, e.g. with `kind load docker-image`.
5. Read the `intro.md` in each scenario's directory and follow the steps. You can run the `verify.sh` scripts to automatically check your solutions.
