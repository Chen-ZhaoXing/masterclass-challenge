from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def read_root():
    return {"service": "sleigh-telemetry", "status": "operational"}

@router.get("/health")
def health_check():
    return {"healthy": True}

@router.get("/telemetry")
def get_telemetry():
    return {
        "altitude": 30000,
        "speed": 650,
        "reindeer_power": "nominal",
        "gift_payload": "secured"
    }
