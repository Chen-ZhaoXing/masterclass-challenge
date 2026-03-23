import fastapi
import api


def create_app():
    app = fastapi.FastAPI(title="Sleigh Telemetry Service")
    app.include_router(api.router)
    return app

app = create_app()
