"""请求上下文中间件：注入 trace_id / request_id。"""
from __future__ import annotations

import logging
import time
from typing import Any

from flask import Flask, g, request

from app.auth.decorators import resolve_user_from_request
from app.observability.context import RequestContext, generate_id, set_request_context
from app.observability.logger import get_logger, log_event


def register_request_context_middleware(app: Flask) -> None:
    """注册请求上下文与访问日志中间件。"""
    access_logger = get_logger("middleware.access")

    @app.before_request
    def inject_request_context() -> None:
        trace_id: str = request.headers.get("X-Trace-Id") or generate_id("trace")
        request_id: str = generate_id("req")
        span_id: str | None = request.headers.get("X-Span-Id")
        context = RequestContext(
            trace_id=trace_id,
            request_id=request_id,
            span_id=span_id,
            client_ip=request.remote_addr,
            method=request.method,
            path=request.path,
        )
        set_request_context(context)
        g.request_started_at = time.perf_counter()
        g.trace_id = trace_id
        g.request_id = request_id
        current_user = resolve_user_from_request()
        if current_user is not None:
            g.current_user = current_user
            g.user_id = current_user["user_id"]
        log_event(
            access_logger,
            logging.INFO,
            "http.request.received",
            f"收到请求 {request.method} {request.path}",
            query=dict(request.args),
            content_length=request.content_length,
            user_id=getattr(g, "user_id", None),
        )

    @app.after_request
    def attach_trace_headers(response: Any) -> Any:
        response.headers["X-Trace-Id"] = getattr(g, "trace_id", "-")
        response.headers["X-Request-Id"] = getattr(g, "request_id", "-")
        started_at: float | None = getattr(g, "request_started_at", None)
        duration_ms: float = 0.0
        if started_at is not None:
            duration_ms = round((time.perf_counter() - started_at) * 1000, 2)
        log_event(
            access_logger,
            logging.INFO,
            "http.request.completed",
            f"请求完成 {request.method} {request.path} -> {response.status_code}",
            status_code=response.status_code,
            duration_ms=duration_ms,
        )
        return response
