# Scenario Objective: Require Service Account

The rogue elves' "gift-tracking" API is now properly labeled, but they've left a glaring security hole. They deployed their application using the `default` service account!

By using the default service account, the application might inherit overly broad permissions, potentially granting a mischievous Grinch access to the North Pole's central Naughty/Nice database!

The Chief Information Security Elf (CISE) has firmly rejected this deployment. To maintain a secure holiday environment, all applications must use a dedicated service account to enforce the principle of least privilege.

## Your Task

Your next mission is to configure a specific `serviceAccountName` for the application to satisfy the North Pole's strict security policies and avoid using the `default` account. Use the service account `gift-tracking-sa`.

1. Open the `app.yaml` manifest.
2. Create the service account `gift-tracking-sa`.
3. Add the `serviceAccountName: gift-tracking-sa` field under the pod's `spec` section.
4. Save the file and verify your solution with `k apply -f app.yaml`!
5. Click the `Check` button!

## Bonus
The Chief Information Security Elf (CISE) has also requested that the service account token not be mounted to the pod.