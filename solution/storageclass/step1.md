## Correct Answer to add in statefulset.yaml
```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: "mongodb-service"
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongodb
          image: mongo:8.2.6
          ports:
            - containerPort: 27017
          envFrom:
            - secretRef:
                name: mongodb-secret
          volumeMounts:
            - name: mongodb-data
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongodb-data
      spec:
        accessModes: ["ReadWriteOnce"]  # <-- Add this line
        storageClassName: "local-path"  # <-- Add this line
        resources:
          requests:
            storage: 5Gi
```
