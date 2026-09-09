from django.db import models


class Toy(models.Model):
    """A toy on Santa's build list, as registered in the workshop catalog."""

    name = models.CharField(max_length=120)
    flavor = models.CharField(max_length=120)
    price_cents = models.PositiveIntegerField()
    featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = "catalog"
        ordering = ["name"]

    def as_dict(self):
        return {
            "name": self.name,
            "flavor": self.flavor,
            "price_cents": self.price_cents,
            "featured": self.featured,
        }
