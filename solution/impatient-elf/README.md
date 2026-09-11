# The Impatient Elf - Solution Guide

## The Bug

The `gift-registry` Deployment declares two regular containers: the Django **shop** (`gift-registry`) and the catalog **restocker** (`elf`). Kubernetes starts all regular containers of a Pod **at the same instant, in parallel** — so the shop boots while the elf is still rebuilding the catalog. Because the elf's job is `TRUNCATE` + full restock, the shelves are *emptied* at the start of the rebuild; the shop's startup check (`catalog_status --require-populated`) runs a second or two later, finds zero rows, exits 1, and the Pod crash-loops. Every restart re-runs the same race and loses the same way.

The elf's work is "must finish first" work — exactly what `initContainers` are for. It was declared in the wrong list.

## How to Diagnose

```bash
# The Pod crash-loops
kubectl get pods -n workshop

# Per-container logs. Ask for each container by name: `--all-containers --previous`
# fails outright, because wait-for-db has never restarted and so has no previous run.
kubectl -n workshop logs deploy/gift-registry -c gift-registry --previous
# shop: shop cannot open: catalog not ready (ProgrammingError: no usable catalog table)
#       (or: shelves are empty (0 toys in catalog), depending on how far the elf got)
kubectl -n workshop logs deploy/gift-registry -c elf
# elf:  [elf] rebuilding the toy catalog from the workshop ledger...

# The Deployment spec shows the tell:
kubectl -n workshop get deployment gift-registry -o yaml
#   initContainers: [ wait-for-db ]
#   containers:     [ gift-registry, elf ]      <-- the elf is here
```

Compare how `wait-for-db` is declared (initContainer, runs first, exits 0) versus how `elf` is declared (regular container, starts in parallel with the app). The timing in the logs — elf still mid-restock when the shop's check runs — confirms the race.

## The Fix

One structural change in `~/app.yaml`: move the `elf` container from `containers:` to `initContainers:`, after `wait-for-db`. Leave only `gift-registry` under `containers:`.

```yaml
spec:
  template:
    spec:
      initContainers:
        - name: wait-for-db
          ...
        - name: elf          # moved here: migrate + restock, then exit 0
          ...
      containers:
        - name: gift-registry  # starts only after ALL initContainers succeeded
          ...
```

```bash
kubectl apply -f ~/app.yaml
kubectl -n workshop get pods -w    # fresh Pod: initContainers finish, then 1/1 Running, 0 restarts
```

A full reference manifest is provided in `app.yaml`.

## Why It Matters

**initContainers** are the Kubernetes mechanism for ordered, must-succeed startup work:

- they run **sequentially**, in the order listed in the spec;
- each one must **exit with code 0** before the next starts;
- the app containers only start **after every init container has finished**.

The production patterns behind this challenge:

- run **database migrations / seeding** as initContainers (or better, as a job), never as a sibling container that races the app;
- a **probabilistic** race becomes a **deterministic** failure when the "loser" side clears state first (TRUNCATE + rebuild) — which is exactly what made this bug 100% reproducible and 100% verifiable;
- when debugging a crash loop, read the **per-container logs of the previous attempt** (`kubectl logs -c <container> --previous`) and compare **declared container order vs. actual start order** in the Pod spec.
