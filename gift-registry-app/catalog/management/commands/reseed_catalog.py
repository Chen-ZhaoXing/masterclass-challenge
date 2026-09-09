"""Rebuild the toy catalog from the workshop ledger.

Idempotent by design — the elf may run this as many times as needed:

  1. TRUNCATE the catalog (clear the shelves, as any good elf would),
  2. restock it in full from the deterministic ledger,
  3. ANALYZE so the planner knows the new shape of the tables.

The rebuild is intentionally heavy (tens of thousands of rows across many
batched inserts) so that it reliably takes longer than the app's startup
check — which is exactly why it must be an initContainer: the shop must not
open until the elf is done.
"""
import random

from django.core.management.base import BaseCommand
from django.db import connection

from catalog.models import Toy

# A few thousand toys per category keeps the rebuild realistic without
# taking minutes. The default of 15,000 rows is tuned so that the elf's
# rebuild always outlasts the app's startup check on standard lab hardware.
DEFAULT_ROWS = 15000

ADJECTIVES = [
    "zippy", "fuzzy", "sparkly", "chunky", "whistling",
    "glowing", "bouncy", "tinny", "singing", "sturdy",
]
CATEGORIES = [
    "robot", "drum", "kite", "rocket", "train",
    "doll", "blocks", "puzzle", "yo-yo", "marbles",
]
WOODS = ["pine", "maple", "oak", "cedar"]


class Command(BaseCommand):
    help = "TRUNCATE the toy catalog and restock it from the workshop ledger"

    def add_arguments(self, parser):
        parser.add_argument(
            "--rows",
            type=int,
            default=DEFAULT_ROWS,
            help="number of toys to restock (default: %(default)s)",
        )

    def handle(self, *args, **opts):
        rows = max(1, opts["rows"])

        # 1) Clear the shelves. (TRUNCATE, not DELETE: this is a full rebuild.)
        with connection.cursor() as cursor:
            cursor.execute("TRUNCATE TABLE catalog_toy RESTART IDENTITY")

        # 2) Restock from the ledger. Deterministic seed => reproducible catalog.
        rng = random.Random(20261224)
        created = 0
        batch = []
        for i in range(rows):
            batch.append(
                Toy(
                    name=f"{rng.choice(ADJECTIVES)} {rng.choice(CATEGORIES)} No.{i}",
                    flavor=f"{rng.choice(ADJECTIVES).title()} {rng.choice(WOODS)}",
                    price_cents=rng.randint(499, 49999),
                    featured=(i % 97 == 0),
                )
            )
            if len(batch) >= 1000:
                Toy.objects.bulk_create(batch, batch_size=1000)
                created += len(batch)
                batch = []
        if batch:
            Toy.objects.bulk_create(batch, batch_size=1000)
            created += len(batch)

        # 3) Let PostgreSQL learn about the new data.
        with connection.cursor() as cursor:
            cursor.execute("ANALYZE catalog_toy")

        self.stdout.write(self.style.SUCCESS(f"restocked catalog with {created} toys"))
