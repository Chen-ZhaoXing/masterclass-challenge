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

Challenges are scored using **static scoring** on CTFd. A **50-point bonus** is awarded for completing all five challenges.

| Challenge | Difficulty | Points | Time | Key Topics |
|-----------|------------|--------|------|------------|
| The Exposed Coordinates | 🟢 Easy | 100 | ~15 min | Kubernetes Secrets, Helm, Volume Mounts |
| The Frozen Handshake | 🟢 Easy | 100 | ~15 min | TLS trust chains, Volume Mounts, Secret certificates |
| The Bloated Sleigh Image | 🟡 Medium | 200 | ~25 min | Dockerfile, Multi-Stage Builds, Non-Root |
| The Trojan Manifest | 🔴 Hard | 300 | ~40 min | Raw Manifests, Kyverno, Security Context, Probes |
| The Phantom Storage | 🔴 Hard | 300 | ~30 min | PersistentVolumeClaims, StorageClasses, Services |
| Completion Bonus | — | +50 | — | Complete all 5 challenges |
| | | **1050** | **~125 min** | |

Each challenge has **layered hints** — the first hint is free, with subsequent hints costing 10–20% of the challenge points. See [CTFd-Scoring.md](CTFd-Scoring.md) for full hint definitions and CTFd configuration details.

---

## 🚀 Available Scenarios (Ranked by Difficulty)

### 🟢 Easy: The Exposed Coordinates
The Sleigh Routing API is leaking the Master Guidance Coordinates through a plaintext environment variable (`APP_TOKEN`). The rogue elves are actively scraping process trees and container logs to steal this token.
- **Your Mission:** Refactor the deployment to securely mount the Kubernetes Secret as a file and remove the plaintext environment variable, preventing the secret from being exposed in logs and crash dumps.
- **Learning Objectives:** Secrets management, `volumeMounts`, minimizing secret blast radius.

### 🟢 Easy: The Frozen Handshake
The rogue elves turned on TLS for an internal endpoint, but intentionally neglected to mount the trusted CA certificate into the client workload, causing severe connection errors.
- **Your Mission:** Update the client deployment to mount the correct CA cert from a Secret so TLS validation succeeds and the pipeline reconnects!
- **Learning Objectives:** TLS trust chains, CA certificate distribution, runtime verification.

### 🟡 Medium: The Bloated Sleigh Image
The rogue elves have sabotaged the container build pipeline with a 1GB+ Docker image running as root. The North Pole Container Standard demands images under 250 MB with non-root execution.
- **Your Mission:** Rewrite the Dockerfile using multi-stage builds, a slim base image, and a non-root user to produce a secure, production-ready container image.
- **Learning Objectives:** Multi-stage Docker builds, image size optimization, non-root containers, `.dockerignore`, layer caching.

### 🔴 Hard: The Trojan Manifest
The rogue elves have submitted a poorly configured, exploitable raw manifest (`app.yaml`) to deploy a new "gift-tracking" API. Anticipating this, the Chief Holiday Officer has deployed **Kyverno**, a strict Kubernetes policy engine, to reject any resources that do not meet production standards.
- **Your Mission:** Attempt to deploy the manifest, debug the Kyverno policy violations, and refactor the YAML configuration to meet all security and operational requirements.
- **Learning Objectives:** Kyverno admission controllers, container security context (non-root, dropping capabilities), resource requests/limits, liveness/readiness probes, proper workload labeling, ServiceAccount isolation.

### 🔴 Hard: The Phantom Storage
The rogue elves completely wiped the storage boundaries and network services for the MongoDB database and frontend application, ensuring massive data loss and total deployment failure.
- **Your Mission:** Explicitly define the `storageClassName` and `accessModes` in the database, provisions a new `PersistentVolumeClaim` for offline backups, and reconnect the internal Service network.
- **Learning Objectives:** PersistentVolumeClaims, StorageClasses, Access Modes, Kubernetes Networking.

---

## 🛠 Project Structure

- `app/`: Contains the source code and Dockerfiles.
- `scenarios/one/`: Killercoda configuration for The Exposed Coordinates.
- `scenarios/three/`: Killercoda configuration for The Bloated Sleigh Image.
- `scenarios/two/`: Killercoda configuration for The Trojan Manifest.
- `scenarios/four/`: Killercoda configuration for The Frozen Handshake.
- `scenarios/storageclass/`: Killercoda configuration for The Phantom Storage.
- `solution/`: Reference solutions and step-by-step methodology for each challenge.
- `CTFd-Scoring.md`: Full CTFd scoring configuration with point values, hint costs, and setup guide.

---

## 💡 How to Run Locally

If you want to test or modify the challenges locally before pushing to Killercoda:

1. You will need a local Kubernetes cluster (e.g., Minikube, kind, or Docker Desktop).
2. For The Trojan Manifest challenge, you must install [Kyverno](https://kyverno.io/docs/installation/) and apply the policies found in `kyverno-policies/masterclass-policies.yaml`.
3. For The Phantom Storage challenge, ensure a local volume provisioner like `local-path-provisioner` exists.
4. Read the `intro.md` in each scenario's directory and follow the steps. You can run the `verify.sh` scripts to automatically check your solutions.
