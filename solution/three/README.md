# Challenge 2: The Bloated Sleigh Image - Solution

## The Vulnerability
The rogue elves' original Dockerfile was a massive security and operational failure. It built a 1GB+ monolithic container, left cache files inside the layers, and inexcusably ran the application as the `root` Linux user.

## The Solution
We hardened and optimized the container image (`Dockerfile`) using industry best practices for production workloads:

1. **Multi-Stage Builds:** We split the build into a `builder` stage and a production stage. All compilers and raw dependencies are kept in the builder layer and discarded afterward, drastically shrinking the final image to < 250MB.
2. **Slim Base Image:** We utilize `python:3.13-slim` which removes unnecessary operating system binaries that could be used as attack vectors.
3. **Non-Root Execution:** We created a dedicated user `northpole` (UID 10001) and used the `USER` directive to drop privileges. If an attacker eventually compromises the application, they are restricted to this low-privilege user and cannot escalate to host root.
4. **Optimized Layer Caching:** By copying `requirements.txt` and running `pip install` *before* copying the application source code, we ensure that the heavy dependency-installation layer is cached efficiently and never rebuilt unless the dependencies actually change.
