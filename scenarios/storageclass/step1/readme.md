# Scenario Objective: The Missing StorageClass

The rogue elves are at it again! They tried to configure a MongoDB backend for their application, but they never gave it any storage at all - there is no volume claim in the manifest, and nothing in the container mounts one!

If deployed as-is, the MongoDB StatefulSet would rely entirely on the cluster's default storage settings. In some environments, this means the pods will be stuck in a `Pending` state forever. In others, they might provision storage with an unsupported multi-node access mode, corrupting the North Pole's vital gift-tracking databases the moment multiple servers attempt to read it!

The Chief Holiday Officer has instantly rejected this deployment. 

## Your Task

Your first mission in securing the storage layer is to give MongoDB a disk and make it actually write to it:

1. Add a `volumeClaimTemplates` section to the StatefulSet, with `accessModes` and `storageClassName` explicitly set.
2. Add a matching `volumeMounts` entry to the `mongodb` container so the database writes to that claim at `/data/db`.

A claim nothing mounts is just a claim - the data would still vanish on restart.

## What You Have

1. A `statefulset.yaml` manifest for the MongoDB - with no storage in it yet.
2. A `StorageClass` named `local-path`.
3. Requirement for `accessModes` to be `ReadWriteOnce`.
4. Requirement for a 5Gi storage.
5. Click the `Check` button!
