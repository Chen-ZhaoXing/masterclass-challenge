# Step 1: Revoke the Skeleton Key

The gift-tracking workload currently holds unlimited authority over the cluster. Your first job is to take it away.

## Your Task

Establish what the workload's identity is permitted to do today, then remove the grant that gives it cluster-wide power.

Two things must remain true when you are finished:

- The workload's identity must still **exist**. Deleting it is not a fix — the running application depends on it.
- The gift-tracking application must still be **running**. Breaking the service on Christmas Eve is not an acceptable outcome.

At this stage the workload will be left with no permissions at all. That is expected. You will grant back what it legitimately needs in the next step.

Click the `Check` button!
