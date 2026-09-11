# The Impatient Elf - Solution Guide

## The Problem

The `gift-registry` Deployment declares two regular containers: the Django **shop** (`gift-registry`) and the catalog **restocker** (`elf`). Kubernetes starts all regular containers of a Pod **at the same instant, in parallel** — so the shop boots while the elf is still rebuilding the catalog. Because the elf's job is `TRUNCATE` + full restock, the shelves are *emptied* at the start of the rebuild; the shop's startup check (`catalog_status --require-populated`) runs a second or two later, finds zero rows, exits 1, and the Pod crash-loops.

The elf's work is "must finish first" work — exactly what `initContainers` are for. It was declared in the wrong list.

## The Fix

Move the `elf` container from `containers:` to `initContainers:`, after `wait-for-db`. Leave only `gift-registry` under `containers:`.

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

## Why It Matters

**initContainers** are the Kubernetes mechanism for ordered, must-succeed startup work:

- they run **sequentially**, in the order listed in the spec;
- each one must **exit with code 0** before the next starts;
- the app containers only start **after every init container has finished**.

## Production Patterns

- run **database migrations / seeding** as initContainers (or better, as a Job), never as a sibling container that races the app;
- a **probabilistic** race becomes a **deterministic** failure when the "loser" side clears state first (TRUNCATE + rebuild) — which is exactly what made this bug 100% reproducible and 100% verifiable;
- compare **declared container order vs. actual start order** in the Pod spec to diagnose startup timing issues.

A full reference manifest is provided in `app.yaml`.
