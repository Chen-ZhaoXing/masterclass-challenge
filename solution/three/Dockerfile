# --- Stage 1: Build Stage ---
FROM python:3.13-slim AS builder

# Set environment variables to optimize Python for containers
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /build

# Install any system-level build tools (only if needed for C-extensions)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies into a specific directory
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Stage 2: Production Stage ---
FROM python:3.13-slim

WORKDIR /app

# Create a non-root user and group for security
RUN groupadd -g 10001 elf && \
    useradd -u 10001 -g elf -m -s /sbin/nologin northpole

# Copy only the installed site-packages from the builder stage
COPY --from=builder /install /usr/local

# Copy only the application source code (ignoring junk via .dockerignore)
COPY src/ /app/src/

# Set ownership of the app directory to our new user
RUN chown -R northpole:elf /app

# Switch to the non-root user
USER northpole

# FastAPI environment variables
ENV PATH="/home/northpole/.local/bin:${PATH}"

EXPOSE 8000

# Start the application
CMD ["fastapi", "run", "src/app.py", "--host", "0.0.0.0", "--port", "8000"]