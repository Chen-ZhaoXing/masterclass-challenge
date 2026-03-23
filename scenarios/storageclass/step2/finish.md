## Why PVCs and Internal DNS Matter

### 1. PersistentVolumeClaims (PVCs)
In Kubernetes, applications should never handle physical storage directly. Instead, they make a "Claim" for storage (the PVC). This is a critical abstraction because it allows you to request storage requirements (e.g., "I need 1Gi of ReadWriteOnce storage") without needing to know *anything* about the underlying infrastructure (like whether it's an AWS EBS volume, an Azure Disk, or a local hard drive). The PVC acts as a clean contract between your application and the cluster.

### 2. VolumeMounts
Once a PVC is created and bound to physical storage, it must be explicitly mapped into the container's file system using `volumeMounts`. Without this mapping, the container operates entirely using ephemeral memory storage (`tmpfs`), meaning any local database backups, assets, or logs are completely and permanently destroyed the second the pod restarts!

### 3. Internal DNS and Services
By creating the `mongodb-service`, you leveraged Kubernetes' automated internal DNS system. Hardcoding database IP addresses into frontend applications is extremely dangerous because Pod IPs change dynamically every time a container runs or scales. By routing your application traffic through a stable `Service` hostname like `mongodb-service`, Kubernetes handles the orchestration behind the scenes, ensuring the traffic always resolves to the active MongoDB pods!
