![Security alert banner showing a best practices warning](./assets/banner.png)

> **Difficulty:** 🔴 Hard  |  **Points:** 300
>
> **Prerequisites:** Kubernetes deployment manifests, Kubernetes security contexts, basic understanding of admission controllers
>
> **Learning Objectives:** Kyverno policy enforcement, Manifest debugging, container security context (non-root, drop capabilities), resource requests/limits, health probes, standard labeling, ServiceAccount isolation

# The Trojan Manifest

## The Situation

The rogue elves haven't given up. After failing to steal the Master Guidance Coordinates, they are now trying a different approach: deploying insecure, poorly configured workloads into the North Pole Kubernetes cluster to create vulnerabilities they can exploit later.

They've managed to submit a basic Kubernetes deployment manifest (located at `~/app.yaml`) to deploy a new "gift-tracking" API. Unsurprisingly, it's riddled with common security and operational misconfigurations.

## The Countermeasure

Anticipating this, the Chief Holiday Officer has deployed **Kyverno**, a Kubernetes policy engine, across the cluster. Kyverno is armed with `ClusterPolicies` that will outright reject any resources that do not meet the North Pole's production standards.

Your role as Senior Security Elf is to analyze the rogue elves' manifest, identify the misconfigurations blocking its deployment, and refactor it to meet Kyverno's standards.

## Your Mission

1. **Deploy the Manifest:** Attempt to apply the manifest to the cluster to see what happens.
2. **Find the Errors:** When Kyverno blocks the deployment, use the feedback to identify which policies the manifest violates.
3. **Fix the Manifest:** Modify the configuration within `~/app.yaml` so it adheres to all security requirements.
4. **Verify:** You are done when you can successfully deploy the manifest without Kyverno rejecting it.

The cluster has all the information you need. Investigate, debug, and fix.

Good luck, Security Elf. Let's lock this cluster down.
