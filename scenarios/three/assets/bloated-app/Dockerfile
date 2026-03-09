# ============================================================
# WARNING: This Dockerfile was written by the rogue elves.
# It produces a bloated, insecure, 1GB+ image.
# Your mission: rewrite it to meet North Pole Container Standards.
# ============================================================

FROM python:3.13

WORKDIR /app

# Copy EVERYTHING into the image (no .dockerignore!)
COPY . /app

# Install all dependencies (build cache remains in the image)
RUN pip install -r requirements.txt

# Expose the application port
EXPOSE 8000

# Run as root (no USER directive!) — a security nightmare
CMD ["fastapi", "run", "src/app.py", "--host", "0.0.0.0", "--port", "8000"]
