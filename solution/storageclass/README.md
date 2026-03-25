# The Phantom Storage - Solution Guide

This scenario has two steps: restoring the database storage configuration and reconnecting the application's networking and backup volumes.

---

## Step 1: Restoring the Database (StatefulSet + StorageClass)

### What Went Wrong

The `statefulset.yaml` for MongoDB is missing its `volumeClaimTemplates` section entirely. Without this, the StatefulSet has no persistent storage - meaning all database data is stored in ephemeral container memory and lost on every restart.

### How to Diagnose

```bash
kubectl apply -f ~/statefulset.yaml
kubectl get pods                      # Pod may start but has no persistent storage
kubectl get pvc                       # No PVCs exist for the database
kubectl get storageclasses            # Shows "local-path" is available
```

### The Fix

Add the `volumeClaimTemplates` section back to `statefulset.yaml`:

```yaml
          volumeMounts:
            - name: mongodb-data
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongodb-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "local-path"
        resources:
          requests:
            storage: 5Gi
```

Key fields explained:
- **`accessModes: ["ReadWriteOnce"]`** - The volume can be mounted read-write by a single node. This is appropriate for a database since only one MongoDB instance should write to the data directory.
- **`storageClassName: "local-path"`** - Tells Kubernetes which storage provisioner to use. `local-path` uses local node storage (provided by Rancher's local-path-provisioner in this cluster).
- **`storage: 5Gi`** - Requests 5 gigabytes of disk space for the database.

```bash
kubectl apply -f ~/statefulset.yaml
```

### Why It Matters

**StatefulSets** are designed for stateful applications like databases. Unlike Deployments, they provide:
- **Stable pod names** (e.g., `mongodb-0`, `mongodb-1`) for consistent network identity
- **Ordered deployment** - pods start sequentially, not all at once
- **Per-pod persistent storage** via `volumeClaimTemplates` - each replica gets its own PVC

**StorageClasses** abstract away the underlying storage technology. In production, you might use `gp3` (AWS EBS), `pd-ssd` (GCP), or `managed-premium` (Azure) instead of `local-path`.

---

## Step 2: Reconnecting the Application (PVC + Service + Deployment)

### What Went Wrong

Three things are broken:
1. The `gift-tracker` deployment has no persistent volume for backups
2. There's no Service for MongoDB, so the app can't connect to the database
3. The backup PVC doesn't exist

### How to Diagnose

```bash
kubectl get svc                       # No mongodb-service exists
kubectl get pvc                       # No backup-pvc exists
kubectl logs -l app=gift-tracker      # Connection errors to mongodb
```

### The Fix

**1. Create the MongoDB Service:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
    - port: 27017
      targetPort: 27017
```

This creates a DNS entry `mongodb-service` that resolves to the MongoDB pod, allowing the gift-tracker app to connect.

**2. Create the Backup PVC:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
```

**3. Update the Deployment to mount the backup volume:**

Add to the container spec:
```yaml
          volumeMounts:
            - name: backup-volume
              mountPath: /app/data
```

Add to the pod spec:
```yaml
      volumes:
        - name: backup-volume
          persistentVolumeClaim:
            claimName: backup-pvc
```

**4. Apply everything:**
```bash
kubectl apply -f ~/deployment.yaml
```

### Why It Matters

**PersistentVolumeClaims (PVCs)** are how pods request persistent storage. The lifecycle of a PVC is independent of any pod - if the pod dies, the data persists. This is critical for:
- Database data directories
- Application logs
- Backup files
- Uploaded content

**Services** provide stable networking for pods. Without a Service, the gift-tracker app would need to know the MongoDB pod's ephemeral IP address, which changes on every restart. The Service provides a stable DNS name (`mongodb-service`) that always routes to the correct pod.
