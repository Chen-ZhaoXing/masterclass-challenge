# Scenario Objective: Grant Only What Is Needed

The skeleton key is gone, and the gift-tracking workload now has no authority at all. It still has one legitimate job to do tonight: read its own configuration.

The Chief Holiday Officer's audit will test the workload's identity against a list of actions it must be able to perform, and a list it must never be able to perform. Anything granted beyond what it genuinely needs will fail that audit.

## Your Task

1. Grant `gift-tracking-sa` read access to ConfigMaps - and only ConfigMaps.
2. Scope that access to the `gift-tracking` namespace only. Access that reaches into any other namespace will fail the audit.
3. Grant read verbs only. The ability to create, update or delete ConfigMaps will fail the audit.
4. Keep the ServiceAccount and the `gift-tracker` deployment in place.
5. Click the `Check` button!

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
