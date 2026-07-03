"""业务流程追踪。"""
from __future__ import annotations

import logging
import time
from contextlib import contextmanager
from typing import Any, Generator

from app.observability.context import generate_id
from app.observability.logger import get_logger, log_event


class FlowTracer:
    """业务流程序列追踪器。"""

    def __init__(self, module: str, flow_name: str) -> None:
        self._logger = get_logger(module)
        self._flow_name: str = flow_name

    @contextmanager
    def step(self, step_name: str, **extra: Any) -> Generator[str, None, None]:
        """追踪单步业务，自动记录 started/completed/failed。"""
        span_id: str = generate_id("span")
        event_prefix: str = f"{self._flow_name}.{step_name}"
        started_at: float = time.perf_counter()
        log_event(
            self._logger,
            logging.INFO,
            f"{event_prefix}.started",
            f"[{self._flow_name}] 步骤开始: {step_name}",
            span_id=span_id,
            **extra,
        )
        try:
            yield span_id
            duration_ms: float = (time.perf_counter() - started_at) * 1000
            log_event(
                self._logger,
                logging.INFO,
                f"{event_prefix}.completed",
                f"[{self._flow_name}] 步骤完成: {step_name}",
                span_id=span_id,
                duration_ms=round(duration_ms, 2),
                **extra,
            )
        except Exception as exc:
            duration_ms = (time.perf_counter() - started_at) * 1000
            log_event(
                self._logger,
                logging.ERROR,
                f"{event_prefix}.failed",
                f"[{self._flow_name}] 步骤失败: {step_name} - {exc}",
                span_id=span_id,
                duration_ms=round(duration_ms, 2),
                error_type=type(exc).__name__,
                error_message=str(exc),
                **extra,
            )
            raise
