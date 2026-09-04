# The Skeleton Key Is Destroyed

The sleigh launches on time.

You revoked cluster-wide authority from a public-facing workload and replaced it with a single, precisely scoped capability — read its own configuration, in its own namespace, and nothing else. If that workload is compromised tonight, the attacker inherits the ability to read three configuration values. Not the naughty list. Not the routing coordinates. Not the cluster.

## What You Practised

- **Auditing effective permissions** rather than reading manifests and hoping
- **Revoke first, then grant back** — the safe order for changing authorization on a live service
- **Namespace scoping** — why the binding you choose matters as much as the rules you write
- **Least privilege as a working practice**, not a slogan

## Carry This Back

The `temporary, revert after launch` grant is one of the most common findings in real Kubernetes audits. It is almost never reverted, and the workloads that carry it are frequently the ones most exposed to the outside world.

When you next see a permissions error in a deployment pipeline, the question to ask is not *how do I make this go away* — it is *what does this workload actually need?*

The Chief Holiday Officer thanks you. Merry Christmas, Security Elf.
