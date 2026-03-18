![Security alert banner showing a best practices warning](./assets/banner.png)

> **Difficulty:** 🔴 Hard  |  **Time:** ~40 minutes  |  **Points:** 300
>
> **Prerequisites:** Helm chart templating, Kubernetes security contexts, basic understanding of admission controllers
>
> **Learning Objectives:** Kyverno policy enforcement, Helm debugging, container security context (non-root, drop capabilities), resource requests/limits, health probes, standard labeling, ServiceAccount isolation

# The Trojan Helm Chart

## The Situation

The rogue elves haven't given up. After failing to steal the Master Guidance Coordinates, they are now trying a different approach: deploying insecure, poorly configured workloads into the North Pole Kubernetes cluster to create vulnerabilities they can exploit later.

They've managed to submit a basic Helm chart (located in `~/app-chart`) to deploy a new "gift-tracking" API. Unsurprisingly, it's riddled with common security and operational misconfigurations.

## The Countermeasure

Anticipating this, the Chief Holiday Officer has deployed **Kyverno**, a Kubernetes policy engine, across the cluster. Kyverno is armed with `ClusterPolicies` that will outright reject any resources that do not meet the North Pole's production standards.

Your role as Senior Security Elf is to analyze the rogue elves' Helm chart, identify the misconfigurations blocking its deployment, and refactor it to meet Kyverno's standards.

## Your Mission

1. **Deploy the Chart:** Attempt to render and apply the Helm chart to the cluster to see what happens.
2. **Find the Errors:** When Kyverno blocks the deployment, use the feedback to identify which policies the chart violates.
3. **Fix the Chart:** Modify the templates and values within `~/app-chart` so they adhere to all security requirements.
4. **Verify:** You are done when you can successfully deploy the Helm chart without Kyverno rejecting it.

The cluster has all the information you need. Investigate, debug, and fix.

Good luck, Security Elf. Let's lock this cluster down.
