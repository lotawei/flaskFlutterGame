"""结构化日志配置。"""
from __future__ import annotations

import logging
import sys
from typing import Any

from pythonjsonlogger import jsonlogger

from app.config import AppConfig
from app.observability.context import get_request_context


class ContextFilter(logging.Filter):
    """将 trace/request 上下文注入 LogRecord。"""

    def __init__(self, service_name: str) -> None:
        super().__init__()
        self._service_name: str = service_name

    def filter(self, record: logging.LogRecord) -> bool:
        record.service = self._service_name
        context = get_request_context()
        if context is not None:
            for key, value in context.to_log_fields().items():
                setattr(record, key, value)
        else:
            record.trace_id = "-"
            record.request_id = "-"
        if not hasattr(record, "event"):
            record.event = "-"
        if not hasattr(record, "extra_data"):
            record.extra_data = {}
        return True


def setup_logging(config: AppConfig) -> logging.Logger:
    """初始化全局日志。"""
    root_logger: logging.Logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.setLevel(getattr(logging, config.log_level, logging.INFO))
    handler: logging.Handler = logging.StreamHandler(sys.stdout)
    if config.log_format == "json":
        formatter: logging.Formatter = jsonlogger.JsonFormatter(
            fmt="%(asctime)s %(levelname)s %(name)s %(message)s",
            rename_fields={"asctime": "timestamp", "levelname": "level", "name": "module"},
        )
    else:
        formatter = logging.Formatter(
            fmt="%(asctime)s [%(levelname)s] service=%(service)s "
            "trace=%(trace_id)s req=%(request_id)s event=%(event)s "
            "%(name)s - %(message)s",
        )
    handler.setFormatter(formatter)
    handler.addFilter(ContextFilter(config.service_name))
    root_logger.addHandler(handler)
    logging.getLogger("werkzeug").setLevel(logging.WARNING)
    return logging.getLogger(config.service_name)


def get_logger(name: str) -> logging.Logger:
    """获取模块级 logger。"""
    return logging.getLogger(name)


def log_event(
    logger: logging.Logger,
    level: int,
    event: str,
    message: str,
    **extra: Any,
) -> None:
    """按统一 event 字段写日志。"""
    logger.log(level, message, extra={"event": event, "extra_data": extra or {}})
