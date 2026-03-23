![Security alert banner showing a best practices warning](./assets/banner.png)

> **Points:** 300
>
> **Prerequisites:** Kubernetes storage concepts (PV, PVC, StorageClass), basic networking (Services), StatefulSets
>
> **Learning Objectives:** PersistentVolumeClaims, StorageClasses, Access Modes, VolumeMounts, internal Kubernetes Services

# The Missing Storage Classes

## The Situation

The rogue elves haven't given up. After failing to bypass the North Pole's security policies, they are attempting to sabotage the gift-tracking infrastructure at the storage and network layers! 

They know that deploying stateful applications without explicitly defining their storage boundaries is a recipe for data corruption and downtime, especially when migrating from the local development workshops to the harsh production environments of the North Pole. 

They submitted a `statefulset.yaml` for a MongoDB database and a `deployment.yaml` for the frontend Python application. Unsurprisingly, both are intentionally misconfigured to break storage bindings, rely on non-existent defaults, and completely isolate the application.

## The Countermeasure

The Chief Holiday Officer has instituted strict reviews of all storage and network requests. You must step in and configure the infrastructure correctly before the holiday rush begins and the system collapses under its own data!

Your role as the Lead DevOps Elf is to analyze the rogue elves' manifests, identify the missing definitions blocking the deployment, and refactor them to ensure data is safely persisted.

## Your Mission

1. **Secure the Database:** Open `statefulset.yaml` and explicitly define the `accessModes` and `storageClassName` in the volume claim templates to ensure the database mounts correctly.
2. **Create the Volumes:** Define a new `PersistentVolumeClaim` so the application has a place to store its offline backups.
3. **Mount the Storage:** Update the application in `deployment.yaml` to mount your newly created volume to the correct application directory.
4. **Restore Connectivity:** Create the missing Kubernetes `Service` so the isolated application can finally reach the database.

The cluster has all the information you need. Investigate, debug, and fix.

Good luck, DevOps Elf. Let's get this data persisted.
