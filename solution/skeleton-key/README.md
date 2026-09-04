# Solution: The Skeleton Key

## Step 1 — Revoke the Skeleton Key

Audit what the identity currently holds:

```bash
kubectl auth can-i --list --as=system:serviceaccount:gift-tracking:gift-tracking-sa
```

`*.*` on `*.*` confirms cluster-admin. Remove the binding:

```bash
kubectl delete clusterrolebinding gift-tracking-skeleton-key
```

Confirm the identity now holds nothing:

```bash
kubectl auth can-i '*' '*' --as=system:serviceaccount:gift-tracking:gift-tracking-sa
```

The ServiceAccount and the Deployment are deliberately left untouched — both are asserted by the
verify script.

## Step 2 — Grant Only What Is Needed

```bash
kubectl apply -f least-privilege.yaml
```

Or imperatively:

```bash
kubectl create role gift-tracking-config-reader -n gift-tracking \
  --verb=get,list,watch --resource=configmaps
```

```bash
kubectl create rolebinding gift-tracking-config-reader -n gift-tracking \
  --role=gift-tracking-config-reader \
  --serviceaccount=gift-tracking:gift-tracking-sa
```

Confirm:

```bash
kubectl auth can-i get configmaps --as=system:serviceaccount:gift-tracking:gift-tracking-sa -n gift-tracking
```

```bash
kubectl auth can-i get configmaps --as=system:serviceaccount:gift-tracking:gift-tracking-sa -n default
```

Expected: `yes` then `no`.

## Accepted Variations

Verification reads **effective permissions**, so naming is irrelevant and these all pass:

- `Role` + `RoleBinding` (shown above — the canonical answer)
- `ClusterRole` + `RoleBinding` in `gift-tracking` (cluster-scoped rules, namespace-scoped grant)
- Any Role/binding names, any additional no-op labels or annotations

## Rejected Variations

- `ClusterRole` + **ClusterRoleBinding** — grants ConfigMap reads in every namespace; step 2 probes
  `default` and `kube-system` explicitly
- Adding `create`, `update`, `patch` or `delete` on ConfigMaps
- Adding any access to Secrets or Pods
- Deleting the ServiceAccount or the Deployment to make the checks moot
