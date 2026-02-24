# Welcome to Challenge 2: Master Helm & Kyverno Policies

Welcome to the second challenge! In this scenario, you will take on the role of a DevOps engineer tasked with preparing a basic application for production deployment.

We have a simple FastAPI application packaged into a Docker image, and a basic Helm chart has been created to deploy it. However, the initial attempt at writing this Helm chart (located in `~/app-chart`) is poorly configured and full of common misconfigurations.

To ensure our cluster remains secure and stable, we have installed **Kyverno**, a Kubernetes policy engine. Kyverno has been configured with strict `ClusterPolicies` that will outright reject any resources that do not meet our production standards.

### Your Mission

1. **Deploy the Chart:** Attempt to render and apply the Helm chart to the cluster to see what happens.
2. **Find the Errors:** When Kyverno blocks the deployment, use the feedback and logs to identify exactly which policies and rules you are violating.
   *Hint: If you need more details on why your deployment is failing or want to see the policies in action, you can check the Kyverno admission controller logs using:*
   ```bash
   kubectl logs -n kyverno -l app=kyverno -c kyverno
   ```
   *You can also inspect the active policies directly:*
   ```bash
   kubectl get clusterpolicies
   ```
3. **Fix the Chart:** Modify the `Chart.yaml`, `values.yaml`, and templates within `~/app-chart` to resolve all the issues. 
4. **Verify:** You are done when you can successfully template and apply the Helm chart to the cluster without Kyverno rejecting it. You can check your progress by running the `check` command.

Good luck! Have fun debugging and refactoring this chart up to standard!
