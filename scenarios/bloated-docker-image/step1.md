# Your Mission

Rewrite the Dockerfile in `~/bloated-app/` to produce a production-ready container image that meets the North Pole Container Standards. Ensure you apply the full suite of Golden Rules of Dockerfiles, including:
- Multi-stage builds for small image size (<250MB).
- Strategic layer caching (dependencies before code).
- OpenShift SCC-compliant non-root execution (e.g. `USER 1001:0`).
- Parameterization using `ARG`, specifying OCI `LABEL`s, and adding a `HEALTHCHECK`.

The rogue elves' Dockerfile is full of anti-patterns. Investigate it, understand what's wrong, and rebuild the image properly. Push your result to `localhost:30500/sleigh-telemetry:latest`.

> 💡 If you're stuck, purchase hints from the challenge portal for guidance.
