# Scenario Objective: Require Non-Root Container

The rogue elves' "gift-tracking" API is now properly labeled, but they've left a glaring security hole. They configured their application to run as the `root` user!

If a mischievous Grinch manages to exploit a vulnerability in the application, running as root would give them complete control over the container, posing a severe threat to the North Pole's infrastructure and the Naughty/Nice database.

The Chief Information Security Elf (CISE) has firmly rejected this deployment. To maintain a secure holiday environment, all containers must run as a non-root user.

## Your Task

Your next mission is to enforce security restrictions by ensuring the application container does not run as root.

1. Open the `app.yaml` manifest.
2. Add a `securityContext` block under the application container.
3. Set `runAsNonRoot` to `true` within the `securityContext`.
4. Save the file and verify your solution with `k apply -f app.yaml`!
5. Click the `Check` button!

## Bonus
🌟 Drop all the `capabilities` in the `securityContext` to give yourself a boost! 