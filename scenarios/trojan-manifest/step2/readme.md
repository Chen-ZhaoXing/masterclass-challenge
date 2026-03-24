# Scenario Objective: Health Probes

The rogue elves' "gift-tracking" API is now resource-bound, but they forgot something critical: how does the North Pole orchestration engine know if the app is actually ready to receive requests or if it has frozen out in the cold?

Without proper health checks, the routing system might send critical naughty/nice updates to a stalled container, resulting in lost data! 

The Chief Holiday Officer has once again rejected this deployment until it can prove its health.

## Your Task

A new cluster policy is now active that requires the deployment to declare how Kubernetes should check if the application is alive and ready.

1. Try deploying the manifest and read the policy violation.
2. The error message will tell you what type of health checks the policy requires.
3. Fix the manifest and redeploy.
4. Click the `Check` button!

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
