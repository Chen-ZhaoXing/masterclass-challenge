# Step 2: Grant Only What Is Needed

The skeleton key is gone. The gift-tracking workload now has no authority at all — and it still needs to do its job tonight.

## Your Task

Grant the workload's identity exactly the access described in the briefing, and nothing beyond it:

> It reads its own configuration from ConfigMaps, in its own namespace.

Read access only. Its own namespace only. ConfigMaps only.

The Chief Holiday Officer's audit will test the workload's identity against a range of actions it should be able to perform, and a range it must never be able to perform. Anything granted beyond the single capability above will fail the audit — including access that reaches into other namespaces.

The application must still be running when you are done.

Click the `Check` button!
