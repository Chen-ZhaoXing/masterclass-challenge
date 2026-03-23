# ============================================================
# WARNING: This Dockerfile was written by the rogue elves.
# It produces a bloated, insecure, 1GB+ image.
# Your mission: rewrite it to meet North Pole Container Standards.
# ============================================================

# [ANTI-PATTERN] Using 'latest' tag instead of pinning a specific version
FROM python:latest

WORKDIR /app

# [ANTI-PATTERN] Copy EVERYTHING into the image, breaking layer caching
# and leaking secrets/junk (no .dockerignore!)
# Plus, using ADD instead of COPY!
ADD . /app

# [ANTI-PATTERN] Hardcoding secrets in the environment
# Anyone with access to the image can read this!
ENV SLEIGH_API_KEY=NorthPole-Secret-2024

# [ANTI-PATTERN] Installing without --no-cache-dir wastes space
RUN pip install -r requirements.txt

# [ANTI-PATTERN] Running as root (no USER directive!) — a security nightmare
CMD ["fastapi", "run", "src/app.py", "--host", "0.0.0.0", "--port", "8000"]
