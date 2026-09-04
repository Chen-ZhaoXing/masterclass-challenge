# The Skeleton Key

| | |
|---|---|
| **Difficulty** | 🟡 Intermediate |
| **Points** | 200 |
| **Steps** | 2 |
| **Prerequisites** | Kubernetes fundamentals (Pods, Deployments, Namespaces), ServiceAccounts |
| **Learning Objectives** | Kubernetes RBAC, least-privilege authorization, Roles vs ClusterRoles, auditing effective permissions |

## Overview

The gift-tracking ServiceAccount is bound to `cluster-admin` via a ClusterRoleBinding left behind
by a "temporary" fix. Students revoke that binding, then grant back exactly one capability:
read-only access to ConfigMaps in the workload's own namespace.

The workload runs normally throughout — this is a "works, but is wrong" starting state, so nothing
appears broken until the student inspects effective permissions.

## Steps

| Step | Title | Skill Tested |
|------|-------|-------------|
| 1 | Revoke the Skeleton Key | Audit effective permissions; remove a cluster-wide grant without deleting the identity or breaking the service |
| 2 | Grant Only What Is Needed | Author a least-privilege rule set and bind it at the correct scope |

## Files

- `background.sh` - Creates the namespace, ConfigMap, Secret, ServiceAccount, the `cluster-admin` ClusterRoleBinding, and the workload. Applies `$HOME/rbac.yaml`. Ends with `/tmp/setup-finished`.
- `foreground.sh` - Standard sentinel poller.
- `assets/rbac.yaml` - The over-privileged manifest students inspect and replace. Intentionally uncommented.
- `step1/verify.sh` - Asserts the cluster-wide grant is gone, identity survives, service still up.
- `step2/verify.sh` - Allow/deny matrix over effective permissions.

## Verification Notes

Both steps grade with `kubectl auth can-i --as=system:serviceaccount:gift-tracking:gift-tracking-sa`,
which reports **effective permissions**. This makes the challenge fully solution-agnostic:

- `Role` + `RoleBinding` passes.
- `ClusterRole` + `RoleBinding` also passes (namespace-scoped binding of a cluster-scoped rule set).
- `ClusterRole` + `ClusterRoleBinding` **fails**, because `get configmaps` would then be permitted in
  `default` and `kube-system` — which the deny matrix explicitly probes.
- Resource names, Role names and binding names are never asserted. Students may name anything.

**Guards against cheap escapes:**

| Escape | Guard |
|---|---|
| Delete the ServiceAccount so nothing is permitted | Step 1 and 2 both require the ServiceAccount to exist |
| Delete the Deployment so nothing needs permissions | Both steps require `availableReplicas >= 1` |
| Grant read on ConfigMaps cluster-wide | Step 2 denies `get configmaps` in `default` and `kube-system` |
| Grant write access "just in case" | Step 2 denies `create`/`update`/`delete` on ConfigMaps |

Step 2 re-checks `* *` so a student cannot re-add the skeleton key after passing step 1.

Validated locally against a kind cluster: 11/11 cases correct, including every escape above.

## Wiring Checklist

- [x] `scenarios/structure.json` — course ordering entry added
- [x] `details.finish` declared in `index.json` (most other scenarios omit this, so their finish pages never render)
- [ ] `README.MD` — scoring table row + tier section + project structure list
- [ ] `CTFd-Scoring.md` — scoring table row, tiered hints, difficulty summary, "all N challenges" bonus wording
- [ ] Recompute grand total, total est. time, completion-bonus threshold

Points (200) and difficulty (🟡 Intermediate) are a proposal — the two scoring documents were left
unedited so the point value and hint pricing remain a deliberate decision rather than an assumed one.

## Suggested CTFd Hints

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Kubernetes can tell you exactly what an account is permitted to do, without you reading a single manifest. Find that command and point it at the workload's ServiceAccount before changing anything. |
| 2 | 30 pts | The cluster-wide grant is a ClusterRoleBinding. Removing it leaves the ServiceAccount with no permissions — that is the correct intermediate state. Do not delete the ServiceAccount itself. |
| 3 | 60 pts | Create a Role in the `gift-tracking` namespace with `verbs: [get, list, watch]` on `resources: [configmaps]` in the core (`""`) API group, then bind it to the ServiceAccount with a RoleBinding **in that namespace**. A ClusterRoleBinding will fail the audit because it grants the access in every namespace. |
