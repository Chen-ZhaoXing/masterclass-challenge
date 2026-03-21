# Scenario Objective: Thwarting the Insecure Deployment

To pass Kyverno's checks and secure the North Pole cluster, you must identify and fix the intentional misconfigurations left by the rogue elves in their manifest. 

A well-configured manifest is essential for reliable, scalable, and secure operations during the holiday rush.

## North Pole Security Requirements

In this scenario, you must refactor the chart to address multiple issues across several categories:

- **Resource Limits:** Workloads must not consume unbounded resources.
- **Health Probes:** The cluster must know if applications are healthy and ready to serve traffic.
- **Configuration Management:** Hardcoding configurations instead of correctly templating them is unacceptable.
- **Observability:** Workloads require standard Kubernetes labels to ensure proper routing and tracking.
- **Security Context:** Containers must run with the least possible privilege to minimize the attack surface.
- **Service Accounts:** Workloads must not rely on the default ServiceAccount.

> 💡 **Tip:** If you need specific actionable guidance on how to implement these requirements, refer to the available hints on the challenge portal.