# 🎄 The Impatient Elf

A Kubernetes challenge about **Pod startup ordering**. A Django **gift-registry** app crash-loops in front of PostgreSQL because the workload that restocks its database — *the elf* — was declared as a **regular container** instead of an **initContainer**. Kubernetes starts all regular containers of a Pod at the same instant, in parallel, so the shop keeps opening while the shelves are still being (re)stocked — and the elf clears the shelves before restocking them, so the shop *always* finds them empty, fails its startup check, and the Pod crash-loops forever.

## Why the bug is deterministic

The classic "migrate as a sidecar" bug is only a *probabilistic* race: after a crash-loop or two, the migration is already applied and the app may start fine. This scenario is engineered so it **cannot** self-heal:

- the elf's rebuild is `TRUNCATE` + full restock (15,000 rows, batched inserts + `ANALYZE`) — a real "rebuild the reference dataset" job;
- the shop's entrypoint gates startup on `manage.py catalog_status --require-populated` (table exists **and** non-empty), run *before* gunicorn starts.

So on **every** Pod start: elf truncates at t≈1s and is still loading at t≈5–15s, while the shop checks at t≈2–4s → always empty shelves → always exit 1 → `CrashLoopBackOff`. When the elf is an initContainer, the same job finishes first, the shop sees a full catalog, and stays up. No luck of the draw — the bug is 100% reproducible and the fix 100% verifiable.

## Scenario package

```
index.json            scenario definition (intro/steps/finish + assets + backend)
intro.md              story + brief
finish.md             wrap-up explaining initContainers
background.sh         env setup: provisioner, namespace, DB secret, PostgreSQL,
                      app Service, app Deployment (declared assets under /var/impatient-elf/)
foreground.sh         waits for background, deploys the FIXED ~/app.yaml
step1/
  readme.md           Step 1 — fix the deployment by moving the elf to initContainers
  verify.sh           checks the fixed Deployment spec AND the healthy shop
assets/
  app.yaml            **the Deployment** (elf under `containers:` or `initContainers:`) —
                      the only player-facing file (uploaded to ~/)
  setup/              setup-only manifests (uploaded to /var/impatient-elf/,
                      applied by background.sh; not player-facing)
local-test/           authoring aid: local kind/minikube test harness
```

## Images

Two images, one codebase (the shop and the elf share the Django project), built from `gift-registry-app/` at the repo root:

| Image | Entrypoint | Job |
|---|---|---|
| `newbieshine/gift-registry:2.4.1` | `entrypoint-app.sh` | `catalog_status --require-populated` gate, then gunicorn on :8000 |
| `newbieshine/elf:1.7.0` | `entrypoint-elf.sh` | `migrate` + `reseed_catalog` (TRUNCATE + restock + ANALYZE), then exit 0 |

Build and push them before uploading the scenario. Note these two live under
`newbieshine/`, not the `touching/` account the older scenarios' images use -
`touching` belongs to a different maintainer and cannot be pushed to:

```bash
cd gift-registry-app
make docker
```

## Solution

Lives in `solution/impatient-elf/` (authoring/grading only — **do not upload**; it is deliberately not declared in `index.json`'s assets, so it never appears in the player's environment).

The fix: move the `elf` container from `containers:` to `initContainers:` (after `wait-for-db`). The guaranteed start order then becomes:

```
wait-for-db (init) → elf: migrate + restock, exit 0 (init) → gift-registry
```

## Test locally (kind or minikube)

```bash
# 1) bring up a cluster (kind example)
kind create cluster --name elf

# 2) build + load the two images
cd gift-registry-app
make docker   # or: docker build + kind load, see local-test/test.sh
cd ../scenarios/impatient-elf
./local-test/test.sh build
./local-test/test.sh load

# 3) (optional) deploy the BROKEN environment to see the crash loop
#    ./local-test/test.sh deploy-broken

# 4) apply the fix and watch it come up clean
./local-test/test.sh deploy-fixed
kubectl -n workshop get pods -w        # → 1/1 Running, 0 restarts
```
