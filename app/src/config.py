import os
from dotenv import load_dotenv

class Config:
    def __init__(self):
        self.mode = self.init_env()
        self.app_token = ""

    def init_env(self) -> str:
        mode = os.getenv("MODE", "development".strip().lower())

        if mode == "development":
          self.app_token = os.getenv("APP_TOKEN", "")
        elif mode == "production":
          self.app_token = self.get_app_token()
        else:
          raise ValueError(f"Invalid mode: {mode}")
        return mode

    def get_app_token(self) -> str:
        if self.mode == "development":
          return os.getenv("APP_TOKEN")
        else:
            app_token_path = os.getenv("APP_TOKEN_PATH", "")
            if not app_token_path:
                raise ValueError("APP_TOKEN_PATH is not set")
            with open(app_token_path, "r") as f:
                return f.read().strip()
