# Scenario Objective: The Missing StorageClass

The rogue elves are at it again! They tried to configure a MongoDB backend for their application, but they intentionally left out the storage boundaries and configurations in their data claims!

If deployed as-is, the MongoDB StatefulSet would rely entirely on the cluster's default storage settings. In some environments, this means the pods will be stuck in a `Pending` state forever. In others, they might provision storage with an unsupported multi-node access mode, corrupting the North Pole's vital gift-tracking databases the moment multiple servers attempt to read it!

The Chief Holiday Officer has instantly rejected this deployment. 

## Your Task

Your first mission in securing the storage layer is to explicitly define `accessModes` and `storageClassName` within the MongoDB.

## What You Have

1. A `statefulset.yaml` manifest for the MongoDB.
2. A `StorageClass` named `local-path`.
3. Requirement for `accessModes` to be `ReadWriteOnce`.
4. Requirement for a 5Gi storage.
5. Click the `Check` button!
