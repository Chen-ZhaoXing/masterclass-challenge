# Scenario Objective: The Missing App Connectivity

The rogue elves didn't stop at the database layer. They also completely ruined the application's `deployment.yaml` manifest before leaving for their milk-and-cookies break!

First, they completely removed the `volumes` and `volumeMounts` configuration from the gift-tracking app. Without a persistent volume mounted precisely to `/app/data`, the application can't write its critical offline backup files! 

Second, they deleted the internal Kubernetes `Service` that routes traffic to the MongoDB StatefulSet. Because the application expects to connect to a host named `mongodb-service`, it is currently flying blind and completely isolated from the database!

## Your Task

Your final mission is to restore the application's storage and network connectivity!

1. Open the `deployment.yaml` manifest.
2. Define a new `PersistentVolumeClaim` that requests `1Gi` of `ReadWriteOnce` storage using the `local-path` storage class. Name the `PersistenVolumeClaim`: `backup-pvc`
3. Inside the `gift-tracker` pod spec, add a `volumes` section that links to your new `PersistentVolumeClaim`.
4. Update the container to include `volumeMounts`, mounting the volume to exactly `/app/data`.
5. Finally, create a Kubernetes `Service` named `mongodb-service` that targets the MongoDB StatefulSet labels (`app: mongodb`) on port `27017`!
6. Save your files and apply them to the cluster (`kubectl apply -f deployment.yaml`).
7. Click the `Check` button!
