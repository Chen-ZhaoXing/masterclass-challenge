# Scenario Objective: Thwarting the Insecure Deployment

To pass Kyverno's checks and secure the North Pole cluster, you must identify and fix the intentional misconfigurations left by the rogue elves in their Helm chart. 

A well-configured Helm chart is essential for reliable, scalable, and secure operations during the holiday rush.

## North Pole Security Requirements

In this scenario, you must refactor the chart to address the following issues:

- **Missing Resource Requests and Limits:** Failing to specify CPU and memory requests and limits can lead to unpredictable operations and node starvation, which we cannot afford on Christmas Eve.
- **Missing or Incorrect Liveness and Readiness Probes:** Without proper health checks, the cluster cannot effectively route Sleigh traffic or recover from application deadlocks.
- **Hardcoded Configuration Values:** Embedding environment-specific settings or secrets directly into YAML templates instead of utilizing `values.yaml` or Kubernetes Secrets.
- **Lack of Proper Labels and Selectors:** Inconsistent standard labels break routing and observability. You must implement standard `app.kubernetes.io/name` and `app.kubernetes.io/instance` labels.
- **Running Containers as Root:** Neglecting to define proper `securityContext` settings (such as `runAsNonRoot: true`), unnecessarily expanding the container's attack surface.
- **Failing to Drop Capabilities:** Leaving Linux capabilities enabled by default rather than dropping `ALL` capabilities and only adding what is strictly required. 
- **Using the Default Service Account:** Relying on the `default` ServiceAccount instead of explicitly creating and assigning a least-privilege ServiceAccount for the workload.
- **Missing Image Pull Configuration:** Forgetting to properly configure `imagePullPolicy`.