# The rogue elves swear this image was "fully patched last quarter."
# It wasn't. The base image and several dependencies are years out of date.
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
# gcc is needed only because PyYAML 5.3.1 predates prebuilt wheels for this
# interpreter and has to compile from source - not part of the lesson itself.
# pip is removed from the final image afterwards: a runtime image has no reason
# to carry a package manager. That hardening is already done, leave it in place.
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    pip install --no-cache-dir -r requirements.txt && \
    apt-get purge -y --auto-remove gcc && \
    rm -rf /var/lib/apt/lists/* && \
    python -m pip uninstall -y pip

COPY src/ /app/src/

RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app:app", "--app-dir", "src", "--host", "0.0.0.0", "--port", "8000"]
