> **Points:** 150

<br>

# 🎁 Well sledded!

**The bug.** In the broken Deployment, `elf` was declared as a **regular container**, sitting next to `gift-registry` under `containers:`. Kubernetes starts all regular containers of a Pod **at the same instant, in parallel** — so the shop kept booting while the elf was still rebuilding the catalog. And because the elf clears the shelves (`TRUNCATE`) before restocking them, the shop *always* found the shelves empty, failed its startup check, and crash-looped. Every restart re-ran the same race, and the impatient elf lost every time.

**The fix.** Move the elf's work into **`initContainers:`**. Init containers:

1. run **sequentially**, in the order listed in the spec;
2. must **exit with code 0** before the next one starts;
3. are **all guaranteed to have finished** before any regular container — the shop — is even started.

That's why `wait-for-db` was already living in `initContainers` and doing its job: it was the only member of the team that understood the queue.

## Why It Matters

You just fixed one of the most common "why does my pod crash-loop?" bugs in the wild: a workload that must finish **before** the app starts was declared in the wrong list. The production practices you used:

- read **Pod events and per-container logs** (`--all-containers --previous`) instead of guessing,
- compare **declared order vs. actual start order** in the Pod spec,
- and use **initContainers** for one-shot, must-complete-first work (migrations, seeding, config waits).

The registry is up, the shelves are full, and — for the first time this season — the elf is patient. 🎄
