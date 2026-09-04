# Scenario Objective: Revoke the Skeleton Key

The gift-tracking workload is running with unlimited authority over the entire North Pole cluster. A rogue elf on the release crew handed it a skeleton key during the last deployment window and never took it back.

Your first mission is to take that authority away - without breaking the service three hours before launch.

## Your Task

1. Establish what the workload's identity, `gift-tracking-sa`, is currently permitted to do.
2. Inspect the authorization manifest the rogue elf left behind: `cat ~/rbac.yaml`{{exec}}
3. Remove the grant that gives the workload cluster-wide power.
4. Leave the ServiceAccount itself in place - the running application depends on it.
5. Keep the `gift-tracker` deployment running.
6. Click the `Check` button!

The workload will be left with no permissions at all after this step. That is expected - you will grant back what it legitimately needs in the next step.

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
