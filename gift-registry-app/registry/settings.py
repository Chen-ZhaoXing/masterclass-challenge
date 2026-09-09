"""
Django settings for the gift-registry project.

Configuration comes from the environment (the Deployment injects it), so the
same image works for the app and for the elf's management commands.
"""
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SECRET_KEY = os.environ.get(
    "SECRET_KEY",
    "dev-insecure-key-do-not-use-in-production-0000000000",
)

DEBUG = os.environ.get("DEBUG", "false").lower() == "true"

# The Shop talks to customers over plain http inside the cluster; keep it permissive.
ALLOWED_HOSTS = ["*"]

INSTALLED_APPS = [
    "django.contrib.contenttypes",
    "django.contrib.staticfiles",
    "catalog",
]

MIDDLEWARE = [
    "django.middleware.common.CommonMiddleware",
]

ROOT_URLCONF = "registry.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
            ],
        },
    },
]

WSGI_APPLICATION = "registry.wsgi.application"

# Database — injected by the Pod env (POSTGRES_HOST/PORT/DB/USER/PASSWORD).
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB", "giftregistry"),
        "USER": os.environ.get("POSTGRES_USER", "elf_ops"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD", ""),
        "HOST": os.environ.get("POSTGRES_HOST", "workshop-db"),
        "PORT": os.environ.get("POSTGRES_PORT", "5432"),
    }
}

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_TZ = True
STATIC_URL = "static/"
