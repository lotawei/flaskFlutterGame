"""请求上下文：trace_id / request_id 线程级存储。"""
from __future__ import annotations

import uuid
from contextvars import ContextVar
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class RequestContext:
    """单次请求的可观测上下文。"""
    trace_id: str
    request_id: str
    span_id: str | None = None
    client_ip: str | None = None
    method: str | None = None
    path: str | None = None

    def to_log_fields(self) -> dict[str, Any]:
        """转为日志附加字段。"""
        fields: dict[str, Any] = {
            "trace_id": self.trace_id,
            "request_id": self.request_id,
        }
        if self.span_id:
            fields["span_id"] = self.span_id
        if self.client_ip:
            fields["client_ip"] = self.client_ip
        if self.method:
            fields["http_method"] = self.method
        if self.path:
            fields["http_path"] = self.path
        return fields


_request_context: ContextVar[RequestContext | None] = ContextVar(
    "request_context",
    default=None,
)


def generate_id(prefix: str = "") -> str:
    """生成短 UUID 标识。"""
    short_id: str = uuid.uuid4().hex[:16]
    if prefix:
        return f"{prefix}-{short_id}"
    return short_id


def set_request_context(context: RequestContext) -> None:
    """设置当前请求上下文。"""
    _request_context.set(context)


def get_request_context() -> RequestContext | None:
    """获取当前请求上下文。"""
    return _request_context.get()


def get_trace_id() -> str:
    """获取 trace_id，无上下文时生成临时值。"""
    context: RequestContext | None = get_request_context()
    if context is not None:
        return context.trace_id
    return generate_id("trace")


def get_request_id() -> str:
    """获取 request_id。"""
    context: RequestContext | None = get_request_context()
    if context is not None:
        return context.request_id
    return generate_id("req")
