# The Bloated Sleigh Image - Solution Guide

## The Vulnerability

The rogue elves' Dockerfile has multiple problems:
- **1GB+ image** using unoptimized base image (`python:3.13` is ~1GB)
- **Running as root** - if compromised, the attacker has full container access
- **No layer caching** - every code change rebuilds all dependencies
- **No metadata** - no labels or health checks

## How to Diagnose

```bash
# Build the original Dockerfile and check its size
docker build -t sleigh-telemetry:broken .
docker images sleigh-telemetry:broken
# SIZE: ~1.2GB

# Check who it runs as
docker run --rm sleigh-telemetry:broken whoami
# Output: root
```

## The Fix

Rewrite the `Dockerfile` using these production best practices:

### 1. Multi-Stage Build

Split into two stages: a `builder` that installs dependencies, and a lean production image that copies only what's needed.

```dockerfile
# Stage 1: Builder
FROM python:3.13 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Production
FROM python:3.13-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY src/ ./src/
```

The `--prefix=/install` flag installs packages to a known directory so we can copy them cleanly. The `--no-cache-dir` prevents pip from storing download caches in the image.

### 2. Slim Base Image

`python:3.13-slim` (~150MB) strips out compilers, man pages, and development tools that aren't needed at runtime. This dramatically reduces the attack surface and image size.

### 3. Layer Caching Optimization

By copying `requirements.txt` BEFORE `src/`, Docker caches the expensive `pip install` layer. It only re-runs when dependencies change, not when you change application code.

### 4. Non-Root User

```dockerfile
USER 1001:0
```

Running as a non-root user (UID 1001, GID 0) means an attacker who compromises the app can't modify system files or escalate privileges. The `1001:0` format is also compatible with OpenShift's Security Context Constraints (SCC).

### 5. Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1
```

This lets container orchestrators detect unresponsive containers and restart them.

### 6. Metadata Labels

```dockerfile
LABEL maintainer="security-elf@northpole.int"
LABEL version="1.0"
```

### Build and Push

```bash
docker build -t localhost:30500/sleigh-telemetry:latest .
docker push localhost:30500/sleigh-telemetry:latest
```

### Verify Size

```bash
docker images localhost:30500/sleigh-telemetry
# SIZE: ~180MB (down from 1.2GB)
```

## Why It Matters

Container image security follows the **principle of least privilege**:
- **Smallest possible image** = fewer binaries for attackers to exploit
- **Non-root execution** = attacker can't escalate to host root
- **Multi-stage builds** = build tools (compilers, make) don't ship to production
- **Layer caching** = faster CI/CD pipelines, less registry bandwidth
