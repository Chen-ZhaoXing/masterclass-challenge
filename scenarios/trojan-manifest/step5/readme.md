# Scenario Objective: Container Security Context

The rogue elves' "gift-tracking" API is almost production-ready, but they've left the worst security hole of all. They configured their application to run with elevated privileges!

If a mischievous Grinch manages to exploit a vulnerability in the application, running with full privileges would give them complete control over the container, posing a severe threat to the North Pole's infrastructure and the Naughty/Nice database.

The Chief Information Security Elf (CISE) has firmly rejected this deployment. To maintain a secure holiday environment, all containers must run with restricted privileges.

## Your Task

A new cluster policy is now active that enforces a restricted security posture for all containers.

1. Try deploying the manifest and read the policy violation.
2. The error message will tell you which security setting is required.
3. Fix the manifest and redeploy.
4. Click the `Check` button!

## Bonus
🌟 Drop all unnecessary Linux capabilities in the `securityContext` to give yourself a boost!