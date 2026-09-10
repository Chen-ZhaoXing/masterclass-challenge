# Scenario Objective: Diagnose the Crash Loop

The `gift-registry` Pod in namespace `workshop` will not stay up. It starts, lives for a few seconds, and comes back down — over and over.

Investigate with `kubectl` — describe, logs, events, and the Deployment spec — and work out **why** it crash-loops. The Pod runs two workloads (the shop and the elf), so pay close attention to **when** each of them starts relative to the other, and to what each of them does on boot.

When you're confident about the root cause, write it down in `~/root-cause.txt` (a sentence or two is plenty), then continue.

Useful commands (click to run):

- `kubectl -n workshop get pods`{{exec interrupt}}
- `kubectl -n workshop describe pod -l app=gift-registry`{{exec interrupt}}
- `kubectl -n workshop logs -l app=gift-registry --all-containers --previous`{{exec interrupt}}
- `kubectl -n workshop get deployment gift-registry -o yaml`{{exec interrupt}}

If `--previous` reports that no previous container was found, the Pod hasn't crashed yet — wait a few seconds and run it again.

1. Read the Pod events and the logs from both containers (including the previous crash).
2. Open the Deployment spec: `kubectl -n workshop get deployment gift-registry -o yaml`{{exec interrupt}}
3. Work out *why* the two workloads are fighting each other.
4. Write your root cause to `~/root-cause.txt`.
5. Click the `Check` button!

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
