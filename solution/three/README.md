# Challenge 2: The Bloated Sleigh Image - Solution

## The Vulnerability
The rogue elves' original Dockerfile was a massive security and operational failure. It built a 1GB+ monolithic container, left cache files inside the layers, skipped all standard metadata definitions, and inexcusably ran the application as the `root` Linux user.

## The Solution
We hardened and optimized the container image (`Dockerfile`) using industry best practices for production workloads:

1. **Multi-Stage Builds:** We split the build into a `builder` stage and a production stage. All compilers and raw dependencies are kept in the builder layer and discarded afterward, drastically shrinking the final image to < 250MB.
2. **Slim Base Image:** We utilize `python:${PYTHON_VERSION}-slim` (parameterized via `ARG`) which removes unnecessary operating system binaries that could be used as attack vectors.
3. **Optimized Layer Caching:** By explicitly copying `requirements.txt` and running `pip install` *before* copying the application source code `src/`, we ensure that the heavy dependency layer is cached efficiently and never rebuilt unless the dependencies actually change.
4. **Metadata:** Defined standardized OCI `LABEL`s to identify the image maintainer and version.
5. **Readiness Probe:** Added a `HEALTHCHECK` instruction to notify container orchestrators (like Kubernetes) if the underlying application becomes unresponsive.
6. **SCC-Compliant Non-Root Execution:** We formatted the final environment to be strictly compliant with enterprise Security Context Constraints (like OpenShift's `restricted-v2`) by applying `USER 1001:0` and dropping all privileges before defining the `CMD`. If an attacker compromises the application, they cannot escalate to host root.
