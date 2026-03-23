## Correct Answer to add in deployment.yaml
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  clusterIP: None  # Or a standard ClusterIP service
  selector:
    app: mongodb
  ports:
    - port: 27017
      targetPort: 27017
---
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gift-tracker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gift-tracker
  template:
    metadata:
      labels:
        app: gift-tracker
    spec:
      containers:
        - name: tracker
          image: touching/gift-tracker:latest
          envFrom:
            - configMapRef:
                name: gift-tracker-config
          env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: MONGO_INITDB_ROOT_USERNAME
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: MONGO_INITDB_ROOT_PASSWORD
          # Solution for Volume Mount
          volumeMounts:
            - name: backup-volume
              mountPath: /app/data
      # Solution for persistent volume claim
      volumes:
        - name: backup-volume
          persistentVolumeClaim:
            claimName: backup-pvc
```

## Correct Answer for connecting
```
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

