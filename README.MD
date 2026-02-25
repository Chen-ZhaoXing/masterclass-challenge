# Kubernetes Security Masterclass Challenges

Welcome to the **Kubernetes Security Masterclass Challenges**! This repository contains a series of interactive, hands-on scenarios designed to test and improve your Kubernetes security and operational best practices.

These challenges are hosted on [Killercoda](https://killercoda.com/), providing an interactive, browser-based Kubernetes environment where you can deploy manifests, debug issues, and secure clusters in real-time.

👉 **[Play the Challenges on Killercoda Here](https://killercoda.com/touching/course/scenarios)**

---

## 🎄 The Storyline: The Rogue Elf Faction

Tensions are high at the North Pole. A rogue faction of elves is attempting to sabotage the holiday season by hijacking the sleigh's automated routing system and deploying insecure workloads into the North Pole Kubernetes cluster. 

As the **Senior Security Elf**, it is your job to stop them. The Chief Holiday Officer is counting on you to lock down the cluster, secure the Master Guidance Coordinates, and ensure that only production-ready, strictly validated workloads are allowed to run.

---

## 🚀 Available Scenarios

### Challenge 1: The Exposed Coordinates
The Sleigh Routing API is leaking the Master Guidance Coordinates through a plaintext environment variable. The rogue elves are actively scraping process trees and container logs to steal this token.
- **Your Mission:** Refactor the deployment to securely mount the Kubernetes Secret as a file and remove the plaintext environment variable, preventing the secret from being exposed in logs and crash dumps.
- **Learning Objectives:** Secrets management, `volumeMounts`, minimizing secret blast radius.

### Challenge 2: The Rogue Elf Faction Returns
The rogue elves have submitted a poorly configured, exploitable Helm chart to deploy a new "gift-tracking" API. Anticipating this, the Chief Holiday Officer has deployed **Kyverno**, a strict Kubernetes policy engine, to reject any resources that do not meet production standards.
- **Your Mission:** Attempt to deploy the chart, debug the Kyverno policy violations, and refactor the Helm chart templates to meet all security and operational requirements.
- **Learning Objectives:** Helm templating, Kyverno admission controllers, container security context (non-root, dropping capabilities), resource requests/limits, liveness/readiness probes, and proper workload labeling.

### Challenge 3: TBD
Multi docker stage build.

---

## 🛠 Project Structure

- `app/`: Contains the source code and Dockerfile for the FastAPI applications used in the challenges.
- `scenarios/one/`: Killercoda environment setup, verify scripts, and markdown instructions for Challenge 1.
- `scenarios/two/`: Killercoda environment setup, Kyverno policies, vulnerable Helm chart, verify scripts, and markdown instructions for Challenge 2.

---

## 💡 How to Run Locally

If you want to test or modify the challenges locally before pushing to Killercoda:

1. You will need a local Kubernetes cluster (e.g., Minikube, kind, or Docker Desktop).
2. For Scenario 2, you must install [Kyverno](https://kyverno.io/docs/installation/) and apply the policies found in `scenarios/two/assets/kyverno-policies.yaml`.
3. Read the `intro.md` in each scenario's directory and follow the steps. You can run the `verify.sh` scripts to automatically check your solutions.
