# Scenario Objective: Request and limits

The rogue elves tried to sneak in their "gift-tracking" API without specifying any CPU or Memory boundaries! 

If deployed as-is, a single run-away process or intentional memory leak could consume all of the underlying node's resources, starving critical North Pole systems (like the Naughty/Nice database). 

The Chief Holiday Officer's Kyverno policy has instantly rejected this deployment. 

## Your Task

Your first mission is to define `resources`, specifically `requests` and `limits` for both `cpu` and `memory`, on the application container.

1. Open the `app.yaml` manifests.
2. Locate the container definition.
3. Add appropriate `requests` and `limits` (for example, `100m` CPU and `128Mi` memory).
4. Save the file and verify your solution with `k apply -f app.yaml`!