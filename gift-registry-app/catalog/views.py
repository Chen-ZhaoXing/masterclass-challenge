from django.db import connection
from django.http import JsonResponse

from .models import Toy


def index(request):
    return JsonResponse(
        {
            "service": "gift-registry",
            "endpoints": ["/toys", "/healthz"],
        }
    )


def healthz(request):
    """Liveness/readiness endpoint.

    Touches the catalog on purpose: an un-migrated or un-stocked database
    makes this 500, which is exactly what we want the shop to be unable to
    serve with empty shelves.
    """
    with connection.cursor() as cursor:
        cursor.execute("SELECT count(*) FROM catalog_toy")
        rows = cursor.fetchone()[0]
    return JsonResponse({"status": "ok", "catalog_rows": rows})


def toys(request):
    qs = list(Toy.objects.order_by("name")[:25])
    return JsonResponse({"toys": [t.as_dict() for t in qs]})
