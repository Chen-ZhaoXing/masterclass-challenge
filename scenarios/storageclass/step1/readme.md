# Scenario Objective: The Missing StorageClass

The rogue elves are at it again! They tried to configure a MongoDB backend for their application, but they intentionally left out the storage boundaries and configurations in their data claims!

If deployed as-is, the MongoDB StatefulSet would rely entirely on the cluster's default storage settings. In some environments, this means the pods will be stuck in a `Pending` state forever. In others, they might provision storage with an unsupported multi-node access mode, corrupting the North Pole's vital gift-tracking databases the moment multiple servers attempt to read it!

The Chief Holiday Officer has instantly rejected this deployment. 

## Your Task

Your first mission in securing the storage layer is to explicitly define `accessModes` and `storageClassName` within the MongoDB StatefulSet's `volumeClaimTemplates`.

1. Open the `statefulset.yaml` manifest.
2. Locate the `volumeClaimTemplates` section for `mongodb-data`.
3. Add `accessModes: ["ReadWriteOnce"]` to ensure safe, exclusive access to the database volume.
4. Add `storageClassName: "local-path"` to explicitly request the North Pole's storage provisioner.
5. Save the file and verify your solution! (Usually `kubectl apply -f statefulset.yaml` helps spot indentation errors!)
6. Click the `Check` button!
