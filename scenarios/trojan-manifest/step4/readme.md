# Scenario Objective: Service Account Isolation

The rogue elves' "gift-tracking" API is now properly labeled, but they've left a glaring security hole. They deployed their application using the cluster's default identity!

By using the default service account, the application might inherit overly broad permissions, potentially granting a mischievous Grinch access to the North Pole's central Naughty/Nice database!

The Chief Information Security Elf (CISE) has firmly rejected this deployment. To maintain a secure holiday environment, all applications must use a dedicated identity to enforce the principle of least privilege.

## Your Task

A new cluster policy is now active that prohibits the use of the default identity.

1. Try deploying the manifest and read the policy violation.
2. The error message will tell you what's missing.
3. Create the required resource and update your manifest.
4. Click the `Check` button!

## Bonus
🌟 The Chief Information Security Elf (CISE) has also requested that unnecessary token mounts be disabled. Investigate how to lock this down for an extra achievement!