# Scenario Objective: Container Image Best Practices

## What Developers Will Learn

This scenario teaches developers to stop building bloated, insecure container images by applying production-grade Dockerfile best practices.

## North Pole Container Standards

To pass this challenge, participants must fix a deliberately bad Dockerfile to meet the following requirements:

- **Multi-Stage Build:** Separate build-time dependencies from the runtime image. The build stage handles dependency installation (pip, compilers, headers), while the final stage contains only the application code and its runtime dependencies.
- **Minimal Base Image:** Use `python:3.13-slim` (or equivalent minimal image) for the final stage instead of the full `python:3.13` image which includes an entire Debian installation.
- **Non-Root Execution:** Create a dedicated system user and group, and set the `USER` directive so the container process never runs as root (UID 0).
- **Image Size Under 150 MB:** The final image must be smaller than 150 MB. The original bloated image is over 1 GB.
- **Application Still Works:** After all optimizations, the FastAPI app must still start and respond on port 8000.

## What's Wrong With the Starting Dockerfile

| Anti-Pattern | Impact |
|---|---|
| Uses `python:3.13` (full Debian) | ~1 GB base image with compilers, man pages, and hundreds of unnecessary packages |
| No multi-stage build | pip cache, build headers, and wheel files bloat the final image |
| No `USER` directive | Container runs as root — a container escape gives full host access |
| No `.dockerignore` | `.git/`, `__pycache__/`, and dev files are sent to the build context |
| Single COPY for everything | Cache is busted on every source code change, forcing full reinstall |
