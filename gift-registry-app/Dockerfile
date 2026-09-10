# gift-registry image — the Django "shop" (gunicorn on :8000).
#
# Build:  docker build -t newbieshine/gift-registry:2.4.1 .
# (run from this directory, or: make docker)
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /srv/registry

# Install dependencies first for layer caching.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run as an unprivileged user.
RUN useradd --create-home elfops \
    && chmod +x entrypoint-app.sh entrypoint-elf.sh \
    && chown -R elfops:elfops /srv
USER elfops

EXPOSE 8000
ENTRYPOINT ["sh", "/srv/registry/entrypoint-app.sh"]
