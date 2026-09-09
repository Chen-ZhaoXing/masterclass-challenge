# 🏆 CTFd Scoring & Hint Configuration

This document defines the point allocation, hint costs, and configuration for hosting the Kubernetes Security Masterclass challenges on CTFd.

---

## Scoring Model

**Type:** Static Scoring with Completion Bonus

| # | Challenge | Killercoda Scenario | Difficulty | Base Points | Steps | Est. Time |
|---|-----------|---------------------|------------|-------------|-------|-----------|
| 1 | Trainee Elf Orientation | `scenarios/basics` | 🟢 Beginner | **50** | 3 | ~10 min |
| 2 | Trainee Elf OJT | `scenarios/basics-2` | 🟢 Beginner | **50** | 3 | ~10 min |
| 3 | Trainee Elf Graduation | `scenarios/basics-3` | 🟢 Beginner | **50** | 2 | ~15 min |
| 4 | The Exposed Coordinates | `scenarios/exposed-coordinates` | 🟡 Intermediate | **100** | 1 | ~15 min |
| 5 | The Frozen Handshake | `scenarios/frozen-handshake` | 🟡 Intermediate | **100** | 1 | ~15 min |
| 6 | The Bloated Sleigh Image | `scenarios/bloated-docker-image` | 🟡 Intermediate | **200** | 1 | ~25 min |
| 7 | The Poisoned Present | `scenarios/poisoned-present` | 🟡 Intermediate | **200** | 1 | ~25 min |
| 8 | The Impatient Elf | `scenarios/impatient-elf` | 🟡 Intermediate | **150** | 2 | ~25 min |
| 9 | The Trojan Manifest | `scenarios/trojan-manifest` | 🔴 Advanced | **300** | 5 | ~40 min |
| 10 | The Phantom Storage | `scenarios/storageclass` | 🔴 Advanced | **300** | 2 | ~30 min |
| - | **Completion Bonus** | *All 10 solved* | - | **+100** | - | - |
| | | | **Max Total** | **1600** | | **~210 min** |

---

## Hints Per Challenge

Hints are tiered from vague to specific. The first hint per challenge is **free** to orient participants. Subsequent hints cost a percentage of the challenge's base points.

---

### Challenge 1: Trainee Elf Orientation (50 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Try running `kubectl apply -f ~/typo-app.yaml` and read the error message. It tells you exactly what's wrong. Fix, save, repeat. |
| 2 | 10 pts | There are 3 errors: a misspelled `apiVersion`, a misspelled `kind`, and a YAML indentation problem on the `readinessProbe`. |

**Minimum achievable score:** 40 pts

---

### Challenge 2: Trainee Elf OJT (50 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | These manifests will `kubectl apply` successfully - but the pods will fail. Use `kubectl get pods`, then `kubectl describe pod <name>` or `kubectl logs <name>` to see what's actually wrong inside the cluster. |
| 2 | 10 pts | Step 1: The image name has a typo. Step 2: The `command` references a binary that doesn't exist. Step 3: Create a Secret with `kubectl create secret generic db-credentials --from-literal=DB_PASSWORD=NorthPole2025!` and change the env to use `secretKeyRef`. |

**Minimum achievable score:** 40 pts

---

### Challenge 3: Trainee Elf Graduation (50 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Step 1: The pod is running fine but nothing can reach it. What Kubernetes resource makes a deployment reachable by other pods via DNS? Step 2: The pod can't start because it's missing external configuration - check the Events section of `kubectl describe pod`. |
| 2 | 10 pts | Step 1: Run `kubectl expose deployment gift-dashboard --port=80 --target-port=80` to create a Service. Step 2: Run `kubectl create configmap weather-config --from-literal=APP_MODE=production --from-literal=LOG_LEVEL=info` to create the ConfigMap. |

**Minimum achievable score:** 40 pts

---

### Challenge 4: The Exposed Coordinates (100 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | The secret you need already exists in the cluster. Use `kubectl get secrets -n challenge1` to find it, then `kubectl describe secret <name> -n challenge1` to see its keys. |
| 2 | 15 pts | The application expects `APP_TOKEN_PATH` to point to a file. The secret key `legacy-sys-token` must be mounted as a file named `credentials.key`. Check the TODO comments in `deployment.yaml` for the expected path format. |
| 3 | 25 pts | In your Helm deployment template, add a `volumes[]` entry backed by the Secret with `items[]` mapping the key to the filename. Add a `volumeMounts[]` entry in the container spec with `readOnly: true`. Set `APP_TOKEN_PATH` to `<mountPath>/credentials.key`. Remove the old `APP_TOKEN` env var completely. |

**Minimum achievable score:** 60 pts

---

### Challenge 5: The Frozen Handshake (100 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | The intro tells you everything: a Secret called `northpole-ca` exists with file key `ca.crt`. You need to mount it and set `TLS_CERT_PATH`. Check `deployment.yaml` in the Helm chart for the TODO. |
| 2 | 15 pts | Add a `volumes[]` entry with `secret.secretName: northpole-ca`. Add a `volumeMounts[]` entry pointing to a directory like `/etc/tls`. Set `TLS_CERT_PATH` to `/etc/tls/ca.crt`. Then run `helm upgrade --install challenge4 ~/tls-client-chart -n challenge4`. |

**Minimum achievable score:** 85 pts

---

### Challenge 6: The Bloated Sleigh Image (200 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Look at the existing Dockerfile. What base image is it using? How big is that image? Run `docker images` to see. Check: who is the container running as? Research multi-stage Docker builds and slim base images. |
| 2 | 25 pts | You need a **multi-stage build**: a `builder` stage to install dependencies, and a production stage with `python:3.13-slim`. Copy only pip packages from the builder with `COPY --from=builder`. Use `ARG` for the Python version, add `LABEL` for metadata, and add `HEALTHCHECK`. |
| 3 | 40 pts | Builder: `pip install --no-cache-dir --prefix=/install -r requirements.txt`. Production: `COPY --from=builder /install /usr/local`, then `COPY src/ /app/src/`. Copy `requirements.txt` before `src/` for layer caching. Set `USER 1001:0` (SCC-compliant) before `CMD`. Push to `localhost:30500/sleigh-telemetry:latest`. |

**Minimum achievable score:** 135 pts

---

### Challenge 7: The Poisoned Present (200 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Run `trivy image --severity HIGH,CRITICAL --ignore-unfixed <your-image>` and read both tables it prints. The top table is the OS layer — that one is about your `FROM` line. The bottom table is Python packages. Fix the obvious ones, then scan again: the second scan is where the real lesson is. |
| 2 | 25 pts | Base image: `python:3.9` is end-of-life and gets no patches — move to a currently-supported release. Dependencies: `urllib3`, `Pillow`, `PyYAML` and `requests` are all years behind their patched versions. Bump all four. |
| 3 | 40 pts | Still failing on `starlette`? It isn't in `requirements.txt` — FastAPI pulls it in, and `fastapi==0.115.6` pins it *below* its patched release. An `==` pin caps that package's dependencies too. Bump `fastapi` and prefer `>=` over `==` throughout. |
| 4 | 40 pts | Still failing on `msgpack` and `setuptools`? Neither is installed — Trivy reads them from pip's own vendored dependency list. A runtime image doesn't need a package manager: add `python -m pip uninstall -y pip` to the end of your `pip install` layer. `gcc` can go too once PyYAML is current, since modern PyYAML ships prebuilt wheels. |

**Minimum achievable score:** 95 pts

---

### Challenge 8: The Impatient Elf (150 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Look at the Pod from the inside out: `kubectl -n workshop describe pod -l app=gift-registry`, `kubectl -n workshop logs -l app=gift-registry --all-containers --previous`, and `kubectl -n workshop get deployment gift-registry -o yaml`. Notice *when* each container does its work — and compare how `wait-for-db` is declared in the Pod spec versus how `elf` is declared. |
| 2 | 20 pts | Kubernetes has two container lists in a Pod spec: `initContainers` run one by one and must exit 0 before the app starts, while `containers` all start at the same instant, in parallel. The elf is declared in the wrong list — it belongs in `initContainers`, after `wait-for-db`. |
| 3 | 30 pts | Edit `~/app.yaml`: move the entire `elf` container block from `containers:` into `initContainers:` (keep it after `wait-for-db`), leaving only `gift-registry` under `containers:`. Then `kubectl apply -f ~/app.yaml` and wait for a fresh Pod — the elf's restock takes a few seconds. Verify with `kubectl -n workshop get pods` (1/1 Running, 0 restarts) and the `/healthz` check from step 2. |

**Minimum achievable score:** 100 pts

---

### Challenge 9: The Trojan Manifest (300 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Try `kubectl apply -f ~/app.yaml` and read the error. Each step introduces one new policy. Use the error message to identify which field is missing, then fix it in `app.yaml`. |
| 2 | 30 pts | The 5 policies enforce: (1) `resources.requests` and `resources.limits`, (2) `livenessProbe` and `readinessProbe` with `httpGet`, (3) `app.kubernetes.io/name` and `app.kubernetes.io/instance` labels on `pod.metadata.labels`, (4) a non-default `serviceAccountName`, (5) `securityContext.runAsNonRoot: true`. |
| 3 | 60 pts | For probes, use `httpGet` on path `/` port `8000`. Create a ServiceAccount with `kubectl create sa gift-tracking-sa` and set `serviceAccountName: gift-tracking-sa`. Add `automountServiceAccountToken: false` for bonus points. For security, set `securityContext: { runAsNonRoot: true }` at the container level. |

**Minimum achievable score:** 210 pts

---

### Challenge 10: The Phantom Storage (300 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Step 1: Open `statefulset.yaml` and look at the `volumeClaimTemplates` section. The `storageClassName` and `accessModes` fields are missing. The StorageClass is called `local-path` and the access mode should be `ReadWriteOnce`. |
| 2 | 30 pts | Step 2: Create a PVC named `backup-pvc` with `storageClassName: local-path`, `accessModes: [ReadWriteOnce]`, and `storage: 1Gi`. In `deployment.yaml`, add a `volumes[]` entry referencing your PVC and a `volumeMounts[]` entry mounting it at `/app/data` inside the `tracker` container. |
| 3 | 60 pts | Step 2 (continued): Create a Service named `mongodb-service` targeting the MongoDB pods. Use `selector: { app: mongodb }` and `port: 27017 / targetPort: 27017`. Apply both the PVC, the updated deployment, and the Service with `kubectl apply -f`. |

**Minimum achievable score:** 210 pts

---

## Scoring Summary by Difficulty

| Tier | Challenges | Points Available | Target Audience |
|------|-----------|-----------------|-----------------|
| 🟢 Beginner | Orientation + OJT + Graduation | 150 pts | First-timers, students |
| 🟡 Intermediate | Exposed Coords + Frozen Handshake + Bloated Image + Poisoned Present + Impatient Elf | 750 pts | Workshop graduates |
| 🔴 Advanced | Trojan Manifest + Phantom Storage | 600 pts | Daily practitioners |
| 🏆 Bonus | All 10 completed | +100 pts | Completionists |
| | **Grand Total** | **1600 pts** | |

---

## CTFd Configuration Notes

### Challenge Setup

1. **Challenge Type:** Standard (Static)
2. **Category:** Kubernetes Security
3. **Tags:** Per challenge - e.g., `yaml-debugging`, `secrets`, `helm`, `policy-engine`, `dockerfile`, `multi-stage`, `non-root`, `storage`, `pvc`, `trivy`, `supply-chain`, `cve`, `dependency-management`, `container-security`
4. **State:** Visible (all challenges visible from start; no unlocking required)
5. **Max Attempts:** Unlimited (learning-focused)

### Flag Format

Flags are **not** traditional CTF text flags. Instead, participants are validated by the Killercoda `verify.sh` scripts within the scenario environment. For CTFd submission, consider:

- **Option A (Recommended):** Participants screenshot the `[PASS]` message from verify.sh and submit for manual review
- **Option B:** Generate a unique completion code in verify.sh (e.g., `echo "FLAG{ch1-$(date +%s)-$(hostname)}"`) that participants submit to CTFd
- **Option C:** Use CTFd's "manual challenge" type where proctors verify completion

### Completion Bonus

The 100-point completion bonus for solving all 10 challenges can be implemented as:
- A separate hidden challenge that auto-unlocks when all 10 are solved (requires CTFd plugin), or
- A manual award given by admins after verifying all 10 are complete

### Anti-Cheat Considerations

- **AI-Resistance:** The scenario pages intentionally contain only narrative context - no commands, no exact technical specs, no step-by-step guides. Participants cannot simply paste the intro.md into an AI and get a solution.
- **Verify.sh Hardening:** Error messages describe WHAT failed, not HOW to fix it. Participants must understand the technology to interpret failures.
- **Hint Tiering:** Only purchased CTFd hints contain actionable technical guidance. This creates a clear value proposition for hint purchases.
- **Killercoda Isolation:** Environments are ephemeral, making flag-sharing less useful since each participant must complete the scenario independently.
- Consider using unique per-participant flags generated from hostname/timestamp if using Option B.

---

## Quick-Start: Importing to CTFd

1. Create a new CTFd instance at https://ctfd.io or self-host
2. Create challenges with the point values from the scoring table above
3. Add hints in order with the costs specified (set first hint cost to 0)
4. Set challenge descriptions to match the Killercoda scenario intros (narrative only)
5. Include the Killercoda URL for each scenario in the challenge description
6. Add the completion bonus as a hidden/manual award challenge
