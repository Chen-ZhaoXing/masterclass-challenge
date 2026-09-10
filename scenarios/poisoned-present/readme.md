# The Poisoned Present

| | |
|---|---|
| **Difficulty** | 🟢 Beginner |
| **Points** | 50 |
| **Steps** | 1 |
| **Prerequisites** | Basic Docker/Dockerfile knowledge |
| **Learning Objectives** | Reading a Trivy report, fixed vs. unfixed CVEs, base image freshness vs. size, dependency-pinning hygiene (floors vs. ceilings) |

## Overview

Sequel to **The Bloated Sleigh Image**. The image is slim and non-root already; the vulnerability now is an EOL base image (`python:3.9-slim`) plus four deliberately old, CVE-carrying pinned dependencies (`urllib3`, `Pillow`, `PyYAML`, `requests`).

**Passing requires exactly two file edits, and nothing else:**

1. `Dockerfile` — bump the `FROM` line to a supported release. Clears the entire OS layer (55 findings).
2. `requirements.txt` — bump the four stale `==` pins to `>=` floors. Clears the Python layer.

No other file needs to change, and no edit outside those two files is required. This is deliberate and is what makes the scenario Beginner. See *Design Constraint* below before changing anything.

## Design Constraint (read before editing assets)

This scenario was **downgraded from Intermediate to Beginner**. Two findings that previously required non-obvious fixes have been designed out at the source, not suppressed with an ignore file:

- **Transitive starlette cap.** The old asset pinned `fastapi==0.115.6`, which caps `starlette<0.42`; `starlette 0.41.3` carries fixable HIGH findings that appear nowhere in `requirements.txt`. The asset now ships `fastapi>=0.122.0`, so pip resolves to a current fastapi (and therefore a current starlette) as soon as the base image supports it. **Do not reintroduce an `==` pin on `fastapi`.**
- **pip's vendored manifest.** Trivy parses `pip/_vendor/vendor.txt` and reports pip's bundled `msgpack`/`setuptools` even though neither is importable. The **poisoned** Dockerfile now ends its install layer with `python -m pip uninstall -y pip`, so those findings never reach the student's scan. **Do not remove that line from the asset Dockerfile** — doing so silently makes the challenge unsolvable within the two-file constraint.

The self-check for any future asset edit is: *can a student pass by editing only `Dockerfile` and `requirements.txt`?* The `minimal fix` row in the verification table below is the test for that.

## Steps

| Step | Title | Skill Tested |
|------|-------|--------------|
| 1 | Cleanse the Supply Chain | Base image freshness, dependency version bumps, reading/interpreting a Trivy scan |

## Files

- `assets/sleigh-telemetry/` - the FastAPI application source (same app as `bloated-docker-image`) and the poisoned Dockerfile/requirements.txt
- `background.sh` - reuses the exact registry setup from `bloated-docker-image` (namespace, Deployment, NodePort Service at `localhost:30500`, containerd/Docker insecure-registry trust), then installs Trivy and pre-fetches its vulnerability DB
- `foreground.sh` - builds the poisoned reference image (`:poisoned`) and runs a live Trivy scan against it so students see the oracle before they start
- `step1/verify.sh` - registry check, functional check (service responds on `/health`), then the Trivy oracle

## Environment Setup

The background script:
1. Installs Docker CLI if missing
2. Deploys a registry Deployment + NodePort Service in the `registry` namespace (identical to `bloated-docker-image`)
3. Configures containerd and Docker to trust `localhost:30500` as an insecure registry
4. Installs Trivy from the official apt repo
5. Runs `trivy image --download-db-only` once, so `verify.sh` can run fully offline with `--skip-db-update`
6. Pre-pulls `python:3.9-slim` and `python:3.13-slim`

## Verification Notes

- Oracle command:
  `trivy image --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update --exit-code 1 localhost:30500/sleigh-telemetry:latest`
- `--ignore-unfixed` keeps the check actionable - Trivy findings with no available fix can't be resolved, so they shouldn't block completion.
- The registry-existence and `/health` functional checks exist so a student can't "pass" by pushing an unrelated, trivially-empty image instead of actually fixing this one.
- `verify.sh` never touches the network - the DB is pre-fetched in `background.sh` so the check can't flake on a slow pull.
- `verify.sh` was **not** modified for the difficulty downgrade. The oracle is unchanged; only the asset files moved.

## Verified Build + Scan Results

Run on real `linux/amd64` images (not `--dry-run`, not assumption) against the Trivy DB as of **2026-09-10**, Trivy 0.74.0, Docker 29.4.0.

| Image | Build | Fixable HIGH/CRITICAL | Scan exit | `/health` |
|---|---|---|---|---|
| Poisoned (`assets/sleigh-telemetry` as shipped) | ✅ 0 | 96 (55 OS + 41 Python) | 1 - fails as intended | n/a |
| **Minimal fix** (asset Dockerfile, `FROM` line only + bumped pins) | ✅ 0 | **0** | **0 - passes** | ✅ |
| Reference solution (`solution/poisoned-present`) | ✅ 0 | **0** | **0 - passes** | ✅ |

The **minimal fix** row is the important one: it is the asset Dockerfile with a one-line `FROM` change and the solution's `requirements.txt`, **with `gcc` left in place**. It passes. That proves the two-file constraint holds and that dropping `gcc` is optional polish rather than a hidden requirement.

Both passing images: `/health` returns `{"healthy":true}`, `/telemetry` returns the expected payload, run as `appuser`, 60 MB.

### Poisoned image finding breakdown

| Layer | Package | Findings |
|---|---|---|
| OS (debian 13.1) | `openssl` / `libssl3t64` / `openssl-provider-legacy` | 27 |
| OS | `util-linux` family (`bsdutils`, `libblkid1`, `login`, `mount`, …) | 27 |
| OS | `libcap2` | 1 |
| Python | `Pillow` | 30 |
| Python | `urllib3` | 5 |
| Python | `starlette` | 2 |
| Python | `wheel` | 2 |
| Python | `PyYAML` | 1 |
| Python | `jaraco.context` | 1 |

`starlette`, `wheel` and `jaraco.context` are artifacts of the **old** `python:3.9-slim` interpreter, not of `requirements.txt`. Bumping the base image clears all three, which is why the student never has to reason about them.

Note that `requests==2.24.0` carries **no** fixable HIGH/CRITICAL finding of its own. It still has to be bumped, because it caps `urllib3<1.26` and pip refuses to resolve otherwise:

```
ERROR: Cannot install -r requirements.txt (line 7) and urllib3>=2.2.2
because these package versions have conflicting dependencies.
```

This is a deliberate forcing function: pip itself teaches the floors-vs-ceilings lesson, with an error message that names the conflict. Confirmed by a real `pip install --dry-run` on `python:3.13-slim`.

## Drift Risk (read before each cohort)

This is the only scenario in the course graded against a **live vulnerability feed**. It can break with nobody touching the repo.

The mitigation is structural: **every pin in the solution is a floor (`>=`), never a ceiling**, so a rebuild resolves to whatever is current. The retired starlette bug is the proof of why - the drift risk comes from upper caps, not from pinning as such.

Pre-cohort check:

```bash
REPO=$(git rev-parse --show-toplevel)
CTX=$(mktemp -d)
cp -R "$REPO/scenarios/poisoned-present/assets/sleigh-telemetry/src" "$CTX/"
cp "$REPO/solution/poisoned-present/Dockerfile" "$REPO/solution/poisoned-present/requirements.txt" "$CTX/"

docker build --platform linux/amd64 -t sleigh-telemetry:fixed "$CTX"
trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 sleigh-telemetry:fixed
echo "exit: $?"   # must be 0
```

The build context has to be assembled because the solution's `Dockerfile` and `requirements.txt` are a matched pair - the solution Dockerfile drops `gcc`, which the *asset* `requirements.txt` still needs for PyYAML 5.3.1. A previous version of this document told maintainers to run `docker build -f solution/Dockerfile assets/sleigh-telemetry`, which cannot succeed; that command was wrong and has been replaced.

Also re-run the **minimal fix** check, since that is what students actually produce:

```bash
CTX2=$(mktemp -d)
cp -R "$REPO/scenarios/poisoned-present/assets/sleigh-telemetry/." "$CTX2/"
sed -i'' -e 's|^FROM python:3.9-slim$|FROM python:3.13-slim|' "$CTX2/Dockerfile"
cp "$REPO/solution/poisoned-present/requirements.txt" "$CTX2/requirements.txt"
docker build --platform linux/amd64 -t sleigh-telemetry:minfix "$CTX2"
trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 sleigh-telemetry:minfix
echo "exit: $?"   # must be 0
```

If either fails, look for a new upper bound before assuming the scenario is broken.

## kind Cluster Test (harness end-to-end)

The registry + `verify.sh` half was exercised on a real single-node `kind` cluster (v1.37.0) with NodePort 30500 mapped to the host, using the registry manifest **extracted verbatim** from `background.sh`. Only `verify.sh`'s `broadcast()` transport was stubbed to stdout (macOS has no `/dev/pts`); every check is byte-identical.

| Scenario | Expected | Result |
|---|---|---|
| Registry manifest applies, pod ready, `GET /v2/` | HTTP 200 | ✅ |
| No image in registry | fail at check 1, exit 1 | ✅ |
| `/tmp/trivy-db-failed` present | early explanatory exit, exit 1 | ✅ |
| Poisoned image pushed as `:latest` | checks 1-2 pass, check 3 fails, exit 1 | ✅ |
| Solution image pushed as `:latest` | all pass, exit 0, PASS banner | ✅ |
| Registry round-trip (`docker rmi` then re-pull) | `{"name":"sleigh-telemetry","tags":["latest"]}` | ✅ |

This pass predates the Beginner downgrade, but `verify.sh` and `background.sh` were not changed by it, so the results still hold. Not covered, and still only verifiable on Killercoda itself: the `/dev/pts` broadcast, the apt/systemd/containerd portions of `background.sh`, and asset placement from `index.json`.

### Bug this pass caught

`docker run` failure output was going to `/dev/null`, so an image that could not start at all was reported as *"Service did not respond on /health - did the fix break the app?"* - pointing the student at an application bug that doesn't exist. `--rm` compounded it by deleting the container before its logs could be read. Check 2 now distinguishes "would not start" (prints Docker's own error) from "started but /health didn't answer" (prints the last 8 lines of container output), and drops `--rm` so those logs survive.

## Harness Hardening

- `step1/verify.sh` polls `/health` for up to 15s instead of a fixed `sleep 3`. Uvicorn cold-start on a loaded Killercoda VM can exceed 3s, which would fail a correct solution on timing alone.
- `background.sh` retries the Trivy DB download 3x and writes `/tmp/trivy-db-failed` if all attempts fail. Since `verify.sh` scans with `--skip-db-update`, a silent download failure would otherwise fail every student with a confusing error. `verify.sh` checks that marker first and reports the real cause.
- `foreground.sh` no longer sends `docker build` output to `/dev/null`; a build failure now shows as a build failure with the last 20 log lines, instead of an empty scan table.
- `step1/verify.sh` check 2 separates "the image would not start" from "the image started but `/health` didn't answer", and prints Docker's error or the container's last 8 log lines accordingly. `--rm` was dropped from the `docker run` so a crashed container's logs survive long enough to be read.

## Asset Path Note

`"file": "sleigh-telemetry/**/*"` with `"target": "~/"` is the same declaration `bloated-docker-image` uses for `bloated-app/**/*`, including a nested `src/` directory, and that scenario's `verify.sh` reads `/root/bloated-app/Dockerfile` successfully in production. The pattern is proven; the nested directory is preserved.

## Revision Note

`intro.md`, `step1/readme.md` and `finish.md` were rewritten for the Beginner downgrade. If editing further, keep: the "size != safety" contrast (it is the point of the scenario, and the Before/After table now shows size *unchanged* to make it land), the explicit "exactly two files" framing in `intro.md` and `step1/readme.md`, the floors-vs-ceilings explanation in `finish.md`, and the fixed-vs-unfixed distinction.

The course's anti-AI-assist convention still applies: the scenario text names the two files and the *kind* of problem in each, but never the specific replacement versions. Those live only in the paid CTFd hints.

## Dependency Fix Note (important if editing versions)

The original poisoned pin set (`fastapi==0.131.0` on `python:3.9-slim`, `urllib3==1.26.4`, `requests==2.19.1`) does not build - verified via `pip install --dry-run` and real builds, not assumption:

- `fastapi==0.131.0` requires Python 3.10+ (dropped 3.9 support in 0.129.0) - incompatible with `python:3.9-slim`. The asset now uses `fastapi>=0.122.0`, and pip resolves to the newest release the interpreter supports: an older fastapi on `python:3.9-slim`, a current one once the student bumps the base image.
- `requests==2.19.1` requires `urllib3<1.24`, conflicting with `urllib3==1.26.4`. Fixed by pinning `urllib3==1.23` instead (still carries a real, fixed CVE - see below).
- `fastapi[standard]`'s extras (httpx, email-validator) pull `anyio`, which requires `idna>=2.8` - incompatible with old `requests`' `idna<2.8/<2.9` pin regardless of which old `requests` version is used. Fixed by dropping the `[standard]` extra entirely (the app doesn't need httpx/email-validator/websockets/watchfiles at runtime) and using bare `uvicorn` as the ASGI server instead.
- Switching to `uvicorn` surfaced a second, unrelated bug: `src/app.py` does a bare `import api` rather than a relative import, which only resolves when the app's own directory is on `sys.path` - true for `fastapi run src/app.py` (which does this automatically) but not for `uvicorn src.app:app`. Fixed by running `uvicorn app:app --app-dir src ...` instead, which puts `src/` on the path the same way `fastapi run` did. `CMD` is identical in **both** the poisoned and solution Dockerfiles, so this isn't something a student has to figure out.
- `requests` still needed bumping from `2.19.1` to `2.24.0` to clear the `idna` conflict - this loses CVE-2018-18074 as an available finding, but `urllib3==1.23` independently carries **CVE-2019-11324** (improper certificate validation, CVSS 9.1 CRITICAL, fixed in 1.24.2), so the dependency layer still fails the scan on its own.
- `PyYAML==5.3.1` has no prebuilt wheel for any Python 3.9+ interpreter (it predates Python 3.9's release) and must compile from source, which needs a C compiler. The **poisoned** Dockerfile installs `gcc` before `pip install` and purges it afterward in the same layer. This is why PyYAML was kept at `5.3.1` rather than bumped to `5.4`/`5.4.1` (which have prebuilt wheels but are already patched for **CVE-2020-14343**, CVSS 9.8 CRITICAL - bumping to get a wheel would have silently removed the vulnerability the package is there to teach). The **solution** Dockerfile drops `gcc`, since current PyYAML ships wheels - but the minimal-fix test above confirms leaving it in also passes.
