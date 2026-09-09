#!/bin/sh
#
# Elf entrypoint: rebuild the catalog, then EXIT (a good elf's job is done
# when it ends). This is the work that MUST finish before the shop starts —
# which is precisely why it belongs in an initContainer, not in containers:.
set -e

echo "[elf] applying schema migrations..."
python manage.py migrate --noinput

echo "[elf] rebuilding the toy catalog from the workshop ledger..."
python manage.py reseed_catalog

echo "[elf] shelves restocked. the shop may open."
