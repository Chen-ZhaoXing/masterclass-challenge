# Scenario Objective: Fixing Common Helm Chart Deployment Mistakes

The objective of this scenario is to identify, troubleshoot, and rectify common misconfigurations and mistakes frequently made when deploying applications to Kubernetes using Helm charts. A well-configured Helm chart is essential for reliable, scalable, and secure application deployments.

## Common Mistakes to Address

In this scenario, you will be tasked with fixing the following common Kubernetes and Helm chart mistakes:

- **Missing Resource Requests and Limits:** Failing to specify CPU and memory requests and limits can lead to unpredictable pod eviction, node resource starvation, or inefficient cluster utilization.
- **Missing or Incorrect Liveness and Readiness Probes:** Without proper health checks, Kubernetes cannot effectively manage pod lifecycles, route traffic properly, or automatically recover from application deadlocks or failures.
- **Hardcoded Configuration Values:** Embedding environment-specific settings or secrets directly into the YAML templates instead of utilizing `values.yaml` or Kubernetes Secrets/ConfigMaps, limiting the chart's reusability.
- **Lack of Proper Labels and Selectors:** Inconsistent or missing standard labels can break Service routing, Deployment selectors, and complicate resource management and observability.
- **Running Containers as Root:** Neglecting to define proper `securityContext` settings (such as `runAsNonRoot: true` or `runAsUser`), unnecessarily expanding the container's attack surface and violating security best practices.
- **Failing to Drop Capabilities:** Leaving Linux capabilities enabled by default rather than dropping `ALL` capabilities and only adding what is strictly required, thereby increasing the risk of privilege escalation.
- **Using the Default Service Account:** Relying on the `default` ServiceAccount in a namespace, which often grants unintended permissions to the application, instead of explicitly creating and assigning a least-privilege ServiceAccount.
- **Missing Image Pull Configuration:** Forgetting to configure `imagePullPolicy` properly or omitting `imagePullSecrets` for private registries, leading to deployment failures.