FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .
# gcc is gone: it was only needed because PyYAML 5.3.1 predated prebuilt wheels
# for this interpreter. Current PyYAML ships wheels, so the compiler - and the
# attack surface it drags in - is no longer part of the image at all.
#
# pip is uninstalled in the same layer. Trivy parses pip/_vendor/vendor.txt, so
# pip's *vendored* copies of msgpack and setuptools are reported as findings
# even though neither package is importable. A runtime image does not need a
# package manager, and removing it clears those findings at the source rather
# than suppressing them.
RUN pip install --no-cache-dir -r requirements.txt && \
    python -m pip uninstall -y pip

COPY src/ /app/src/

RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app:app", "--app-dir", "src", "--host", "0.0.0.0", "--port", "8000"]
