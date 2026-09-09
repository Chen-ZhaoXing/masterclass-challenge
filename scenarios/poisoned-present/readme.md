# The Poisoned Present

| | |
|---|---|
| **Difficulty** | 🟡 Intermediate |
| **Points** | 200 |
| **Steps** | 1 |
| **Prerequisites** | Basic Docker/Dockerfile knowledge, comfort reading a vulnerability report |
| **Learning Objectives** | Reading a Trivy report, fixed vs. unfixed CVEs, base image freshness vs. size, pinned dependency hygiene, transitive version caps, keeping build tooling out of runtime images |

## Overview

Sequel to **The Bloated Sleigh Image**. The image is slim and non-root already; the vulnerability now is an EOL base image (`python:3.9-slim`) plus several deliberately old, CVE-carrying pinned dependencies (`urllib3`, `Pillow`, `PyYAML`, `requests`). Students bump the base image and dependency pins until a Trivy scan of the pushed image comes back clean of fixable HIGH/CRITICAL findings.

Clearing the scan takes **four** fixes, not two. The two beyond the obvious ones are deliberate and are the reason this rates Intermediate rather than Beginner:

1. Base image `python:3.9-slim` → a supported release (OS layer).
2. The four stale direct pins (`urllib3`, `Pillow`, `PyYAML`, `requests`).
3. **`fastapi==0.115.6` caps `starlette<0.42`**, and `starlette 0.41.3` carries three fixable HIGH findings. Starlette appears nowhere in `requirements.txt`, so this is only visible in scan output. Teaches that an `==` pin constrains a package's dependencies too.
4. **pip's vendored manifest.** Trivy parses `pip/_vendor/vendor.txt` and reports pip's bundled `msgpack` and `setuptools` as findings, though neither is importable. Unfixable via `requirements.txt`; the fix is `python -m pip uninstall -y pip`, which is also correct practice for a runtime image.

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

- Oracle command (from the challenge design doc):
  `trivy image --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update --exit-code 1 localhost:30500/sleigh-telemetry:latest`
- `--ignore-unfixed` keeps the check actionable - Trivy findings with no available fix can't be resolved, so they shouldn't block completion.
- The registry-existence and `/health` functional checks exist so a student can't "pass" by pushing an unrelated, trivially-empty image instead of actually fixing this one.
- `verify.sh` never touches the network - the DB is pre-fetched in `background.sh` so the check can't flake on a slow pull.

## Known limitation

`details.finish` is declared correctly here (unlike the other 8 scenarios, see guide issue A7.5), but Killercoda apparently doesn't render it anywhere in this repo currently - worth confirming on a live deploy before assuming `finish.md` is visible to students. Because of this, the CTFd screenshot instruction appears in **both** `finish.md` and the `verify.sh` pass banner; the banner is the one students reliably see.

## Verified Build + Scan Results

Run on real `linux/amd64` images (not `--dry-run`, not assumption) against the Trivy DB as of **2026-09-07**, Trivy 0.74.0:

| Image | Build | Fixable HIGH/CRITICAL | Scan exit |
|---|---|---|---|
| Poisoned (`assets/sleigh-telemetry`) | ✅ 0 | 55 OS (52 H / 3 C) + 42 Python (37 H / 5 C) | 1 - fails as intended |
| Solution (`solution/poisoned-present`) | ✅ 0 | **0** | **0 - passes** |

Solution image also confirmed: `/health` returns `{"healthy":true}`, `/telemetry` returns the expected payload, runs as `appuser`, 59 MB.

### Two bugs this testing caught

Both would have made the challenge **unwinnable** - the reference solution itself failed the oracle:

- **`fastapi==0.115.6` caps `starlette<0.42`.** Three fixable HIGH findings (CVE-2025-62727, CVE-2026-48818, CVE-2026-54283) that no edit to the four "obviously stale" pins could clear. Fixed by `fastapi>=0.122.0`, and by using `>=` floors rather than `==` throughout the solution.
- **pip's vendored `msgpack` + `setuptools`.** Reported from `pip/_vendor/vendor.txt`; not installed, not importable, not fixable through `requirements.txt`. Fixed by uninstalling pip in the final layer. `gcc` was dropped at the same time - current PyYAML ships wheels, so the compiler is no longer needed at all.

Both were promoted from accidents into deliberate, hinted parts of the lesson rather than being papered over with an ignore file.

## Drift Risk (read before each cohort)

This is the only scenario in the course graded against a **live vulnerability feed**. It can break with nobody touching the repo.

The mitigation is structural: **every pin in the solution is a floor (`>=`), never a ceiling**, so a rebuild resolves to whatever is current. The starlette bug above is the proof of why - the drift risk comes from upper caps, not from pinning as such.

Pre-cohort check:

```bash
cd solution/poisoned-present
docker build --platform linux/amd64 -t sleigh-telemetry:fixed \
  -f Dockerfile ../../scenarios/poisoned-present/assets/sleigh-telemetry
trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 sleigh-telemetry:fixed
echo "exit: $?"   # must be 0
```

If it fails, look for a new upper bound before assuming the scenario is broken.

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

Not covered by this pass, and still only verifiable on Killercoda itself: the `/dev/pts` broadcast, the apt/systemd/containerd portions of `background.sh`, and asset placement from `index.json`.

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

`intro.md`, `step1/readme.md`, and `finish.md` were trimmed for length/readability after an initial pass, then expanded again to cover the transitive-cap and runtime-tooling lessons. If editing further, keep: the "size != safety" contrast in `intro.md`, the fixed-vs-unfixed distinction in `finish.md`, and the "not every finding maps to a line you can edit" framing in `step1/readme.md`. All three are load-bearing for the lesson, not flavour text.

Per the course's anti-AI-assist convention, `step1/readme.md` states *that* some findings won't map to an editable line but never names starlette or pip - those specifics live only in the paid CTFd hints.

## Dependency Fix Note (important if editing versions)

The original poisoned pin set (`fastapi==0.131.0` on `python:3.9-slim`, `urllib3==1.26.4`, `requests==2.19.1`) does not actually build - verified via `pip install --dry-run` and real builds, not assumption:

- `fastapi==0.131.0` requires Python 3.10+ (dropped 3.9 support in 0.129.0) - incompatible with `python:3.9-slim`. Fixed by pinning `fastapi==0.115.6`, which predates that drop.
- `requests==2.19.1` requires `urllib3<1.24`, conflicting with `urllib3==1.26.4`. Fixed by pinning `urllib3==1.23` instead (still carries a real, fixed CVE - see below).
- `fastapi[standard]`'s extras (httpx, email-validator) pull `anyio`, which requires `idna>=2.8` - incompatible with old `requests`' `idna<2.8/<2.9` pin regardless of which old `requests` version is used. Fixed by dropping the `[standard]` extra entirely (the app doesn't need httpx/email-validator/websockets/watchfiles at runtime) and using bare `uvicorn` as the ASGI server instead.
- Switching to `uvicorn` surfaced a second, unrelated bug: `src/app.py` does a bare `import api` rather than a relative import, which only resolves when the app's own directory is on `sys.path` - true for `fastapi run src/app.py` (which does this automatically) but not for `uvicorn src.app:app`. Fixed by running `uvicorn app:app --app-dir src ...` instead, which puts `src/` on the path the same way `fastapi run` did. `CMD` was updated identically in **both** the poisoned and solution Dockerfiles, so this isn't something a student has to figure out as part of the task.
- `requests` still needed bumping from `2.19.1` to `2.24.0` to clear the `idna` conflict - this loses CVE-2018-18074 as an available finding, but `urllib3==1.23` independently carries **CVE-2019-11324** (improper certificate validation, CVSS 9.1 CRITICAL, fixed in 1.24.2), so the dependency layer still fails the scan on its own.
- `PyYAML==5.3.1` has no prebuilt wheel for any Python 3.9+ interpreter (it predates Python 3.9's release) and must compile from source, which needs a C compiler. The **poisoned** Dockerfile installs `gcc` before `pip install` and purges it afterward in the same layer. This is why PyYAML was kept at `5.3.1` rather than bumped to `5.4`/`5.4.1` (which have prebuilt wheels but are already patched for **CVE-2020-14343**, CVSS 9.8 CRITICAL - bumping to get a wheel would have silently removed the vulnerability the package is there to teach). The **solution** Dockerfile drops `gcc` entirely, since current PyYAML ships wheels.

The poisoned set is now confirmed by a real `docker build` on `linux/amd64`, not only by `pip install --dry-run`.
