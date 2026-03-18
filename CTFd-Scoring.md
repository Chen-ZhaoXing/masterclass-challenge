# 🏆 CTFd Scoring & Hint Configuration

This document defines the point allocation, hint costs, and configuration for hosting the Kubernetes Security Masterclass challenges on CTFd.

---

## Scoring Model

**Type:** Static Scoring with Completion Bonus

| # | Challenge | Killercoda Scenario | Difficulty | Base Points |
|---|-----------|---------------------|------------|-------------|
| 1 | The Exposed Coordinates | `scenarios/one` | 🟢 Easy | **100** |
| 2 | The Bloated Sleigh Image | `scenarios/three` | 🟡 Medium | **200** |
| 3 | The Trojan Helm Chart | `scenarios/two` | 🔴 Hard | **300** |
| — | **Completion Bonus** | *All 3 solved* | — | **+50** |
| | | | **Max Total** | **650** |

---

## Hints Per Challenge

Hints are the **primary guidance mechanism** for participants. The scenario pages intentionally provide only the narrative context and high-level goal — all technical guidance must be purchased here.

Hints are tiered from vague to specific. The first hint per challenge is **free** to orient participants.

### Challenge 1: The Exposed Coordinates (100 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | The secret you need already exists in the cluster. Use `kubectl` to explore the `challenge1` namespace and find it. Look at what keys it contains. |
| 2 | 15 pts | The application expects a new environment variable called `APP_TOKEN_PATH` that points to a file. The secret key `legacy-sys-token` must be mounted as a file named `credentials.key`. |
| 3 | 25 pts | In your Helm deployment template, add a `volumes[]` entry with `secret.secretName` pointing to the secret, using `items[]` to map the key to a filename. Add a `volumeMounts[]` entry in the container spec. Set `APP_TOKEN_PATH` to `{mountPath}/credentials.key`. Remove the old `APP_TOKEN` env var completely. |

**Minimum achievable score:** 60 pts (if all hints unlocked)

### Challenge 2: The Bloated Sleigh Image (200 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Look at the existing Dockerfile. What base image is it using? How big is that image? Research smaller Python base images. Also check: who is the container running as? |
| 2 | 25 pts | You need a **multi-stage build**: one `FROM` stage to install dependencies, and a second `FROM` stage with a minimal base image (like `python:3.13-slim`) for the final runtime image. Copy only the installed packages from the builder. |
| 3 | 40 pts | In the build stage, use `pip install --no-cache-dir --prefix=/install -r requirements.txt`. In the runtime stage, `COPY --from=builder /install /usr/local` to bring only the installed packages. Create a non-root user with `addgroup`/`adduser` and add a `USER` directive before the `CMD`. |

**Minimum achievable score:** 135 pts (if all hints unlocked)

### Challenge 3: The Trojan Helm Chart (300 pts)

| Hint # | Cost | Hint Text |
|--------|------|-----------|
| 1 | **Free** | Run `kubectl get clusterpolicies` to see what Kyverno enforces. Try deploying the chart with `helm template release-name . \| kubectl apply --dry-run=server -f -` and read the error messages carefully. |
| 2 | 30 pts | You need to fix ALL of: standard `app.kubernetes.io/name` and `app.kubernetes.io/instance` labels (check the `_helpers.tpl` for existing label templates), resource limits (not just requests), liveness and readiness probes, a non-default ServiceAccount, and proper security context. |
| 3 | 60 pts | **Watch out:** The deployment template hardcodes `runAsNonRoot: false` even though `values.yaml` says `true` — fix the template. Add `livenessProbe` and `readinessProbe` with `httpGet` on port 8000. Add `limits:` alongside `requests:` in values.yaml. Include `{{ include "app-chart.labels" . }}` in metadata labels for Deployment, Pod template, AND Service. |

**Minimum achievable score:** 210 pts (if all hints unlocked)

---

## CTFd Configuration Notes

### Challenge Setup

1. **Challenge Type:** Standard (Static)
2. **Category:** Kubernetes Security
3. **Tags:** Per challenge — e.g., `secrets`, `helm`, `kyverno`, `dockerfile`, `multi-stage`, `non-root`
4. **State:** Visible (all challenges visible from start; no unlocking required)
5. **Max Attempts:** Unlimited (learning-focused)

### Flag Format

Flags are **not** traditional CTF text flags. Instead, participants are validated by the Killercoda `verify.sh` scripts within the scenario environment. For CTFd submission, consider:

- **Option A (Recommended):** Participants screenshot the `[PASS]` message from verify.sh and submit for manual review
- **Option B:** Generate a unique completion code in verify.sh (e.g., `echo "FLAG{ch1-$(date +%s)-$(hostname)}"`) that participants submit to CTFd
- **Option C:** Use CTFd's "manual challenge" type where proctors verify completion

### Completion Bonus

The 50-point completion bonus for solving all 3 challenges can be implemented as:
- A separate hidden challenge that auto-unlocks when all 3 are solved (requires CTFd plugin), or
- A manual award given by admins after verifying all 3 are complete

### Anti-Cheat Considerations

- **AI-Resistance:** The scenario pages intentionally contain only narrative context — no commands, no exact technical specs, no step-by-step guides. Participants cannot simply paste the intro.md into an AI and get a solution.
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
