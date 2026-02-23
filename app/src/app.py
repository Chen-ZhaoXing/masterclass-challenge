import fastapi
from config import Config
import api


def create_app():
    # lifespan = None
    # if environment == "production":
    config = Config()
    app = fastapi.FastAPI()
    app.include_router(api.router)
    return app

app = create_app()