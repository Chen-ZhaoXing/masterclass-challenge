"""Report whether the catalog is ready to serve.

Exit code 0 = ready (the catalog table exists and is populated).
Exit code 1 = not ready (missing schema, or shelves are empty).

The shop's entrypoint uses `--require-populated` as a hard gate: it refuses
to open for business until the elf has finished rebuilding the catalog.
This is what makes the startup race in the broken Deployment visible — the
shop checks the shelves the instant it boots, and the elf is still working.
"""
from django.core.management.base import BaseCommand
from django.db import connection
from django.db.utils import DatabaseError, OperationalError, ProgrammingError


class Command(BaseCommand):
    help = "Check that the catalog table exists and is populated"

    def add_arguments(self, parser):
        parser.add_argument(
            "--require-populated",
            action="store_true",
            help="exit non-zero if the catalog is missing or empty",
        )

    def handle(self, *args, **opts):
        require = opts["require_populated"]

        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT count(*) FROM catalog_toy")
                rows = cursor.fetchone()[0]
        except (OperationalError, ProgrammingError, DatabaseError) as exc:
            message = f"catalog not ready ({exc.__class__.__name__}: no usable catalog table)"
            if require:
                self.stderr.write(f"shop cannot open: {message}")
                raise SystemExit(1)
            self.stdout.write(message)
            return

        if require and rows == 0:
            self.stderr.write("shop cannot open: shelves are empty (0 toys in catalog)")
            raise SystemExit(1)

        self.stdout.write(self.style.SUCCESS(f"catalog ready: {rows} toys on the shelves"))
