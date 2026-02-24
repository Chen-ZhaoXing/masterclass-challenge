![Security alert banner showing a best practices warning](./assets/banner.png)

# Challenge 2: The Rogue Elf Faction Returns

## The Situation

The rogue elves haven't given up. After failing to steal the Master Guidance Coordinates, they are now trying a different approach: deploying insecure, poorly configured workloads into the North Pole Kubernetes cluster to create vulnerabilities they can exploit later.

They've managed to submit a basic Helm chart (located in `~/app-chart`) to deploy a new "gift-tracking" API. Unsurprisingly, it's riddled with common security and operational misconfigurations—hardcoded secrets, missing resource limits, and containers running as root.

## The Countermeasure

Anticipating this, the Chief Holiday Officer has deployed **Kyverno**, a strict Kubernetes policy engine, across the cluster. Kyverno is armed with `ClusterPolicies` that will outright reject any resources that do not meet the North Pole's rigorous production standards. 

Your role as Senior Security Elf is to analyze the rogue elves' Helm chart, identify the misconfigurations blocking its deployment, and refactor it to meet Kyverno's standards.

## Your Mission

1. **Deploy the Chart:** Attempt to render and apply the Helm chart to the cluster to see what happens.
2. **Find the Errors:** When Kyverno blocks the deployment, use the feedback and logs to identify exactly which policies and rules the chart violates.
   *Hint: If you need more details on why your deployment is failing or want to see the policies in action, check the Kyverno admission controller logs:*
   ```bash
   kubectl logs -n kyverno -l app=admission -c kyverno
   ```
   *You can also inspect the active policies directly:*
   ```bash
   kubectl get clusterpolicies -n kyverno
   ```
3. **Fix the Chart:** Modify `Chart.yaml`, `values.yaml`, and the templates within `~/app-chart` so they adhere to all security requirements.
4. **Verify:** You are done when you can successfully template and apply the Helm chart without Kyverno rejecting it. Run the `check` command to verify your progress.

Good luck, Security Elf. Let's lock this cluster down.
