> **Points:** 150
>
> **Prerequisites:** Basic Kubernetes (Deployments, Pods, initContainers), `kubectl describe` / `kubectl logs`
>
> **Learning Objectives:** Pod startup ordering, initContainers, diagnosing CrashLoopBackOff races

<br>

# The Impatient Elf

## The Situation

It's a week before Christmas and the North Pole Workshop just shipped a new build of the **Gift Registry** — the web app elves use to register the toys on Santa's list. The stack is a classic one: a **Django** app in front of **PostgreSQL**, both running in your Kubernetes cluster.

Except the registry keeps **crash-looping** the moment it boots. The on-call elf left a note in the incident ticket:

> "The shop opens *before* the shelves are stocked — every single time. The logs complain about an empty catalog and then the whole Pod comes back down a minute later. I swear the elf is restocking the shelves *after* the shop opens. One of the rogue elves moved the restocking elf out of the prep shift — **put them back!**"

## Your Mission

Everything is already deployed in namespace `workshop`, including the misbehaving Deployment — its manifest is waiting at `~/app.yaml`. `kubectl` is ready to go.

1. Find out **why** the `gift-registry` Pod refuses to stay up — and write the root cause down in `~/root-cause.txt`.
2. Fix the Deployment so the elf's catalog rebuild is guaranteed to **finish before the shop container starts**.

Happy hunting! 🎅
