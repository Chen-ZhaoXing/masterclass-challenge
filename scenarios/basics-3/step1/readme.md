# Scenario Objective: The Invisible App

The rogue elves deployed the **Gift Dashboard** and it's running perfectly — the pod is `Running`, the container is healthy, all green!

But no other workload in the cluster can reach it. If another application tries to connect to the dashboard, it gets nothing. The dashboard is completely invisible to the rest of the cluster.

In Kubernetes, a running pod is **not** automatically reachable by other pods. Something else is needed to make it discoverable.

## Your Task

1. Apply the manifest: `kubectl apply -f ~/invisible-app.yaml`
2. Verify the pod is running: `kubectl get pods`
3. Now figure out what's missing — why can't anything else connect to this deployment?
4. Create the missing resource to expose the deployment inside the cluster on **port 80**. Use the name `gift-dashboard`.
5. Click the `Check` button!

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
