"""Flask 应用配置。"""
import os
from dataclasses import dataclass


@dataclass(frozen=True)
class AppConfig:
    """应用运行时配置。"""
    service_name: str
    log_level: str
    log_format: str
    debug: bool


def load_config() -> AppConfig:
    """从环境变量加载配置。"""
    return AppConfig(
        service_name=os.getenv("SERVICE_NAME", "meme-game-backend"),
        log_level=os.getenv("LOG_LEVEL", "INFO").upper(),
        log_format=os.getenv("LOG_FORMAT", "json").lower(),
        debug=os.getenv("FLASK_DEBUG", "0") == "1",
    )
