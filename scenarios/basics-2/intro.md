> **Points:** 100
>
> **Prerequisites:** Completed Trainee Elf Orientation, basic `kubectl` commands
>
> **Learning Objectives:** Diagnosing `ImagePullBackOff`, reading `kubectl logs` for crash debugging, Kubernetes Secrets management

# The Trainee Elf OJT

## The Situation

You survived the orientation — impressive! But the Chief Holiday Officer isn't convinced yet. Before you're cleared for the advanced security missions, you need to prove you can **diagnose** problems, not just fix typos.

The rogue elves have left behind three more sabotaged deployments. This time, the manifests will `kubectl apply` just fine — but the pods themselves will fail in different ways. You'll need to use `kubectl describe`, `kubectl logs`, and `kubectl get` to figure out what's actually going wrong inside the cluster.

## Your Mission

1. **The Ghost Container:** A pod is stuck in `ImagePullBackOff`. Something is wrong with the image reference.
2. **The Crash Loop:** A pod keeps restarting in `CrashLoopBackOff`. The application is crashing immediately on startup.
3. **The Hardcoded Password:** A deployment has database credentials hardcoded directly in the manifest. Extract them into a proper Kubernetes `Secret`.

This time, `kubectl apply` won't tell you what's wrong. You'll have to dig deeper.

Good luck, Trainee. Show us you can debug under pressure.
