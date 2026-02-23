from fastapi import APIRouter
from config import Config

router = APIRouter()

@router.get("/")
def read_root():
    return {"Hello": "World"}

@router.get("/token")
def get_token():
    return {"token": Config().get_app_token()}
