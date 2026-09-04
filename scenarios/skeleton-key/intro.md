> **Points:** 200
>
> **Prerequisites:** Kubernetes fundamentals (Pods, Deployments, Namespaces), familiarity with ServiceAccounts
>
> **Learning Objectives:** Kubernetes RBAC, least-privilege authorization, Roles vs ClusterRoles, auditing effective permissions

# The Skeleton Key

## The Situation

Christmas Eve. Three hours to launch.

During the pre-flight audit, the Chief Holiday Officer's team pulled the authorization records for every workload in the North Pole cluster — and found something that stopped the room cold.

The gift-tracking API is running with **unlimited authority over the entire cluster**.

The trail leads back to the last deployment window. A rogue elf on the release crew hit a permissions error, and rather than work out what the workload actually needed, they handed it a skeleton key — total access to everything — and wrote "temporary, revert after launch" in the change log.

It was never reverted.

## Why This Matters

The gift-tracking API is a public-facing service. Anyone who compromises that single workload today inherits the whole cluster: every secret in every namespace, every workload, every node. The naughty list. The routing coordinates. All of it.

The Chief Holiday Officer wants the skeleton key destroyed before launch.

## The Constraint

You cannot simply strip the workload's access and walk away. The gift-tracking API has one legitimate need, and it must keep working through Christmas Eve:

> **It reads its own configuration from ConfigMaps, in its own namespace. Nothing more.**

It never writes to them. It has no business touching Secrets, creating workloads, or reading anything in any other namespace. That single read capability is the entire list.

## What You Have

- **The authorization manifest** the rogue elf left behind, at `~/rbac.yaml`
- **The gift-tracking workload**, running now in its own namespace and expected to stay running
- **Full cluster administrator access**, so you can inspect exactly what any account is permitted to do

Work out what the workload currently holds, take away the skeleton key, and grant back precisely what it needs to survive the night — and not one permission more.

Good luck, Security Elf. The sleigh launches at midnight.
