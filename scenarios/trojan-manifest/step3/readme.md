# Scenario Objective: Standard Labels

The rogue elves' "gift-tracking" API is now resource-bound and proving its health, but they slipped up again. They deployed their application without any identifying metadata!

Without proper labels, the North Pole's automated sled-routing and monitoring systems have no idea which team owns this application or what environment it belongs to. The Chief Holiday Officer's dashboard is showing mysterious, untracked pods, causing panic in the logistics department!

The Chief Holiday Officer has firmly rejected this deployment. All applications must be properly tagged to ensure order in the North Pole.

## Your Task

A new cluster policy is now active that requires standard Kubernetes labels on the pod template.

1. Try deploying the manifest and read the policy violation.
2. The error message will tell you which labels are required and where they should be applied.
3. Fix the manifest and redeploy.
4. Click the `Check` button!

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
