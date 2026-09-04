#!/bin/bash

until kubectl cluster-info >/dev/null 2>&1; do
    sleep 2
done

kubectl create namespace gift-tracking >/dev/null 2>&1
kubectl config set-context --current --namespace=gift-tracking >/dev/null 2>&1

kubectl create configmap gift-tracking-config -n gift-tracking \
    --from-literal=ROUTE_MODE=production \
    --from-literal=SLEIGH_ALTITUDE=1200 \
    --from-literal=LOG_LEVEL=info >/dev/null 2>&1

kubectl create secret generic naughty-list -n gift-tracking \
    --from-literal=entries=classified >/dev/null 2>&1

kubectl apply -f "$HOME/rbac.yaml" >/dev/null 2>&1

kubectl apply -f - >/dev/null 2>&1 <<'MANIFEST'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gift-tracker
  namespace: gift-tracking
  labels:
    app: gift-tracker
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
      serviceAccountName: gift-tracking-sa
      containers:
        - name: tracker
          image: nginx:1.25
          ports:
            - containerPort: 80
          envFrom:
            - configMapRef:
                name: gift-tracking-config
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "200m"
MANIFEST

kubectl wait --for=condition=available deployment/gift-tracker \
    -n gift-tracking --timeout=180s >/dev/null 2>&1

touch /tmp/setup-finished
