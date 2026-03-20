# Scenario Objective: Require Labels

The rogue elves' "gift-tracking" API is now resource-bound and proving its health, but they slipped up again. They deployed their application without any identifying metadata!

Without proper labels, the North Pole's automated sled-routing and monitoring systems have no idea which team owns this application or what environment it belongs to. The Chief Holiday Officer's dashboard is showing mysterious, untracked pods, causing panic in the logistics department!

The Chief Holiday Officer has firmly rejected this deployment. All applications must be properly tagged to ensure order in the North Pole.

## Your Task

Your next mission is to add appropriate `labels`: `app.kubernetes.io/name` and `app.kubernetes.io/instance` to the application's metadata to satisfy the North Pole's strict governance rules. Set the value of both labels to `gift-tracking-app`.

1. Open the `app.yaml` manifest.
2. Add the required `labels` under the `metadata` section.
3. Save the file and verify your solution with `k apply -f app.yaml`!
4. Click the `Check` button!
