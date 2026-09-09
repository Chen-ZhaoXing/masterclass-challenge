from django.urls import path

from catalog import views

urlpatterns = [
    path("", views.index, name="index"),
    path("healthz", views.healthz, name="healthz"),
    path("toys", views.toys, name="toys"),
]
