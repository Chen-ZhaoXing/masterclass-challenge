# Scenario Objective: Resource Boundaries

The rogue elves tried to sneak in their "gift-tracking" API without specifying any CPU or Memory boundaries! 

If deployed as-is, a single run-away process or intentional memory leak could consume all of the underlying node's resources, starving critical North Pole systems (like the Naughty/Nice database). 

The Chief Holiday Officer has instantly rejected this deployment. 

## Your Task

The cluster's policy engine enforcing this requirement is already active. Try deploying the manifest and read the error message - it will tell you exactly which resource fields the policy expects.

1. Open `app.yaml` and attempt to deploy it.
2. Read the policy violation carefully.
3. Fix the manifest to satisfy the policy.
4. Click the `Check` button!

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.