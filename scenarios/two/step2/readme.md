# Scenario Objective: HTTP GET Probes

The rogue elves' "gift-tracking" API is now resource-bound, but they forgot something critical: how does the North Pole orchestration engine know if the app is actually ready to receive requests or if it has frozen out in the cold?

Without proper health checks, the routing system might send critical naughty/nice updates to a stalled container, resulting in lost data! 

The Chief Holiday Officer has once again rejected this deployment until it can prove its health.

## Your Task

Your next mission is to define `livenessProbe` and `readinessProbe` using the `httpGet` action on the application container.

1. Open the `app.yaml` manifests.
2. Add appropriate `livenessProbe` and `readinessProbe` configurations using `httpGet` (for example, pointing to the `/healthz` path on port `8000`).
3. Save the file and verify your solution with `k apply -f app.yaml`!
4. Click the `Check` button!
