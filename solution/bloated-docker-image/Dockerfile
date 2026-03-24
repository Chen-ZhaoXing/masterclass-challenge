# --- Stage 1: Build Stage ---
ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION}-slim AS builder

# [Golden Rule: Explicit root for installation]
USER 0

# [Golden Rule: Label metadata]
LABEL maintainer="security-elf@northpole.com" \
      version="1.0" \
      description="Sleigh Telemetry Service"

# Set environment variables to optimize Python for containers
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /build

# Install any system-level build tools (only if needed for C-extensions)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# [Golden Rule: Layer caching optimization]
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/install -r requirements.txt

# --- Stage 2: Production Stage ---
ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION}-slim

# [Golden Rule: Explicit root for setup]
USER 0

WORKDIR /app

# [Golden Rule: Layer caching optimization]
# Copy dependencies before source code
COPY --from=builder /install /usr/local

# Copy application source code last
COPY src/ /app/src/

# [Golden Rule: OpenShift SCC compliance (USER 1001:0)]
# Ensures the application directory can be read/written by group 0
RUN chown -R 1001:0 /app && chmod -R g=u /app

# FastAPI environment variables
ENV PATH="/usr/local/bin:${PATH}"

EXPOSE 8000

# [Golden Rule: Healthchecks]
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/')" || exit 1

# [Golden Rule: Run as non-root]
USER 1001:0

# Start the application
CMD ["fastapi", "run", "src/app.py", "--host", "0.0.0.0", "--port", "8000"]