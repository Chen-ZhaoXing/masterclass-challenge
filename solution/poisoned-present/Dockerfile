# Two edits clear the scan, and both are in files the student already has open:
#   1. this FROM line - python:3.9 is end-of-life and receives no patches
#   2. the four ancient == pins in requirements.txt
FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .
# gcc is gone. It was only in the poisoned Dockerfile because PyYAML 5.3.1
# predated prebuilt wheels for this interpreter; current PyYAML ships wheels, so
# the compiler - and the attack surface it drags in - is no longer needed.
#
# Dropping gcc is NOT required to pass: the poisoned Dockerfile already purges it
# in the same layer, so it never reaches the final image either way. It is left
# out here because a runtime image that never compiles anything shouldn't ask for
# a compiler at all.
#
# The pip uninstall carries over unchanged from the starter Dockerfile. Trivy
# parses pip/_vendor/vendor.txt, so pip's vendored msgpack and setuptools get
# reported as findings even though neither is importable. The starter image
# already removes pip, which keeps those findings out of the student's scan.
RUN pip install --no-cache-dir -r requirements.txt && \
    python -m pip uninstall -y pip

COPY src/ /app/src/

RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app:app", "--app-dir", "src", "--host", "0.0.0.0", "--port", "8000"]
