#!/bin/sh
#
# Shop entrypoint: the registry only opens for business once the shelves are
# stocked. If the catalog is missing or empty at boot, we exit non-zero and
# let Kubernetes restart us — which is exactly the crash loop players see in
# the broken Deployment (the elf is still restocking when we check).
set -e

echo "[shop] checking that the shelves are stocked before opening..."
python manage.py catalog_status --require-populated

echo "[shop] shelves look full — opening the gift registry"
exec gunicorn registry.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 2 \
    --access-logfile -
