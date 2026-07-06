"""Flask 应用配置。"""
import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class AppConfig:
    """应用运行时配置。"""
    service_name: str
    log_level: str
    log_format: str
    debug: bool
    jwt_secret: str
    jwt_expire_hours: int
    data_dir: Path


def load_config() -> AppConfig:
    """从环境变量加载配置。"""
    default_data_dir = Path(__file__).resolve().parent / "data"
    return AppConfig(
        service_name=os.getenv("SERVICE_NAME", "meme-game-backend"),
        log_level=os.getenv("LOG_LEVEL", "INFO").upper(),
        log_format=os.getenv("LOG_FORMAT", "json").lower(),
        debug=os.getenv("FLASK_DEBUG", "0") == "1",
        jwt_secret=os.getenv("JWT_SECRET", "dev-meme-game-jwt-secret-change-me"),
        jwt_expire_hours=int(os.getenv("JWT_EXPIRE_HOURS", "168")),
        data_dir=Path(os.getenv("DATA_DIR", str(default_data_dir))),
    )
