# The Poisoned Present - Solution Guide

## The Vulnerability

The rogue elves left two problems in the image, and each one lives in a file the student
already has open. Nothing else needs to change.

1. **An EOL base image** - `python:3.9-slim` no longer receives security patches, so every
   OS-layer CVE published since its support window closed is present and unfixed in the
   image. This alone accounts for **55 of the 96 findings**.
2. **Years-old direct pins** - `urllib3==1.23`, `Pillow==8.1.0`, `PyYAML==5.3.1` and
   `requests==2.24.0` all predate published fixes for known HIGH/CRITICAL CVEs, or block
   the packages that do.

## How to Diagnose

```bash
docker build -t sleigh-telemetry:poisoned ~/sleigh-telemetry/
trivy image --severity HIGH,CRITICAL --ignore-unfixed sleigh-telemetry:poisoned
```

Trivy reports two tables: OS packages (from the base image) and Python packages (from
site-packages). The top table maps to the `FROM` line; the bottom maps to `requirements.txt`.

## The Fix

**1. Bump the base image to a currently-supported release:**

```dockerfile
FROM python:3.13-slim
```

**2. Replace the four stale pins with floors:**

```
urllib3>=2.2.2
Pillow>=10.3.0
PyYAML>=6.0.1
requests>=2.32.0
```

`fastapi`, `uvicorn` and `python-dotenv` already ship as `>=` floors in the starter file and
need no change.

**3. Rebuild, push, and confirm:**

```bash
docker build -t localhost:30500/sleigh-telemetry:latest ~/sleigh-telemetry/
docker push localhost:30500/sleigh-telemetry:latest

trivy image --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update --exit-code 1 \
  localhost:30500/sleigh-telemetry:latest

docker run -d --rm -p 8000:8000 localhost:30500/sleigh-telemetry:latest
curl http://localhost:8000/health
```

That is the whole solution. **Verified: the asset Dockerfile with only the `FROM` line
changed, plus the four bumped pins, scans clean and serves `/health` correctly.**

## Why the four pins move together

`requests==2.24.0` carries no fixable HIGH/CRITICAL finding of its own, so students sometimes
try to leave it alone. pip won't let them:

```
ERROR: Cannot install -r requirements.txt (line 7) and urllib3>=2.2.2
because these package versions have conflicting dependencies.
```

`requests==2.24.0` requires `urllib3<1.26`. This is the lesson the scenario is really built
around: **an `==` pin freezes not just the package you named, but everything it depends on.**
A floor (`>=`) lets pip resolve to whatever is current at build time. pip's own error message
delivers the lesson, which is why the scenario text only hints at it.

## About `gcc`

The starter Dockerfile installs `gcc` and purges it in the same layer - it exists only because
PyYAML 5.3.1 predates prebuilt wheels for this interpreter. Once PyYAML is current the compiler
is genuinely unnecessary, and the Dockerfile in this directory drops it.

**Dropping `gcc` is not required to pass.** It is purged inside the same `RUN` layer either
way, so it never reaches the final image. It is removed here because a runtime image that never
compiles anything shouldn't ask for a compiler at all - good practice, not a grading criterion.

## About `pip`

Trivy parses `pip/_vendor/vendor.txt`, so pip's *vendored* copies of `msgpack` and `setuptools`
get reported as findings even though neither is importable. The **starter** Dockerfile already
ends its install layer with `python -m pip uninstall -y pip`, so those findings never appear in
a student's scan.

If you are editing the assets: leave that line alone. Removing it puts findings back on the
board that cannot be cleared by editing `requirements.txt`, which would break the two-file
constraint this scenario is built on.

## Why `--ignore-unfixed`?

Some CVEs Trivy reports have no available patch yet - the maintainer hasn't shipped a fix.
There's nothing actionable to do about those today, so the pipeline (and this challenge)
only fails on **fixable** HIGH/CRITICAL findings. Re-run the scan periodically even after
this challenge is "done": unfixed CVEs become fixed CVEs the moment a patch ships.

## Note for maintainers

This solution is graded against a live vulnerability feed, so it is not frozen in time.
It survives feed drift because every pin is a floor - pip resolves to whatever is current
at build time. It would *not* survive if any pin gained an upper bound. If this challenge
ever starts failing for a correct answer, check for a new upper cap (direct or transitive)
before assuming the scenario is broken.

The `Dockerfile` and `requirements.txt` in this directory are a **matched pair** - this
Dockerfile drops `gcc`, which the *asset* `requirements.txt` still needs. Building this
Dockerfile against the asset directory therefore fails by design. See the pre-cohort commands
in `scenarios/poisoned-present/readme.md` for the correct build contexts.
