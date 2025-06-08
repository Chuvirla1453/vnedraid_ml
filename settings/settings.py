import multiprocessing as mp

from loguru import logger
from pydantic import BaseModel
from pydantic_settings import BaseSettings, SettingsConfigDict

class Uvicorn(BaseModel):
    host: str = "0.0.0.0"
    port: int = 8000
    workers: int = mp.cpu_count() * 2 + 1


class _Settings(BaseSettings):
    uvicorn: Uvicorn = Uvicorn()

    model_config = SettingsConfigDict(env_prefix="app_", env_nested_delimiter="__")


settings = _Settings()
logger.info("settings.inited {}", settings.model_dump_json())