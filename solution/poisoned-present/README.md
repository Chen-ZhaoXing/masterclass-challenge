# The Poisoned Present - Solution Guide

## The Vulnerability

The rogue elves left four separate problems in the image. Only the first two are
visible from a casual read of the Dockerfile; the other two are what make this an
intermediate challenge rather than a find-and-replace exercise.

1. **An EOL base image** - `python:3.9-slim` no longer receives security patches, so every
   OS-layer CVE published since its support window closed is present and unfixed in the image.
2. **Years-old direct pins** - `urllib3==1.23`, `Pillow==8.1.0`, `PyYAML==5.3.1` and
   `requests==2.24.0` all predate published fixes for known HIGH/CRITICAL CVEs.
3. **A capped transitive dependency** - `fastapi==0.115.6` pins `starlette<0.42`, and
   `starlette 0.41.3` carries three fixable HIGH findings of its own. Nothing in
   `requirements.txt` names starlette, so this one is only visible in the scan output.
4. **A package manager in the runtime image** - Trivy parses `pip/_vendor/vendor.txt`, so
   pip's *vendored* copies of `msgpack` and `setuptools` are reported even though neither
   is importable. No edit to `requirements.txt` can clear these.

## How to Diagnose

```bash
docker build -t sleigh-telemetry:poisoned ~/sleigh-telemetry/
trivy image --severity HIGH,CRITICAL --ignore-unfixed sleigh-telemetry:poisoned
```

Trivy reports two tables: OS packages (from the base image) and Python packages (from
site-packages). Read both, and read the `Library` column rather than assuming the findings
map one-to-one onto lines in `requirements.txt` - problems 3 and 4 do not.

## The Fix

**1. Bump the base image to a currently-supported release:**

```dockerfile
FROM python:3.13-slim
```

**2. Replace the stale pins with floors, not ceilings:**

```
fastapi>=0.122.0
urllib3>=2.2.2
Pillow>=10.3.0
PyYAML>=6.0.1
requests>=2.32.0
```

Bumping `fastapi` is what releases the starlette cap. Using `>=` rather than `==`
throughout is the point of the exercise: an upper bound is exactly what made the
original set unfixable.

**3. Drop pip from the final image, and gcc with it:**

```dockerfile
RUN pip install --no-cache-dir -r requirements.txt && \
    python -m pip uninstall -y pip
```

`gcc` was only in the poisoned Dockerfile because PyYAML 5.3.1 predated prebuilt wheels
for this interpreter. Current PyYAML ships wheels, so the whole `apt-get install gcc ...
apt-get purge` dance can go. A runtime image needs neither a compiler nor a package manager.

**4. Rebuild, push, and confirm:**

```bash
docker build -t localhost:30500/sleigh-telemetry:latest ~/sleigh-telemetry/
docker push localhost:30500/sleigh-telemetry:latest

trivy image --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update --exit-code 1 \
  localhost:30500/sleigh-telemetry:latest

docker run -d --rm -p 8000:8000 localhost:30500/sleigh-telemetry:latest
curl http://localhost:8000/health
```

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
