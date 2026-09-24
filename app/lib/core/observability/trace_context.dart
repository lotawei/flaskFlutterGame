import 'package:uuid/uuid.dart';

/// 链路追踪上下文，贯穿一次用户操作。
class TraceContext {
  TraceContext({
    required this.traceId,
    this.spanId,
  });

  final String traceId;
  final String? spanId;

  static const Uuid _uuid = Uuid();

  factory TraceContext.create({String? traceId}) {
    return TraceContext(
      traceId: traceId ?? 'trace-${_uuid.v4().replaceAll('-', '').substring(0, 16)}',
    );
  }

  TraceContext withSpan(String spanId) {
    return TraceContext(traceId: traceId, spanId: spanId);
  }

  TraceContext createChildSpan() {
    return TraceContext(
      traceId: traceId,
      spanId: 'span-${_uuid.v4().replaceAll('-', '').substring(0, 12)}',
    );
  }

  Map<String, String> toHeaders() {
    final Map<String, String> headers = <String, String>{
      'X-Trace-Id': traceId,
    };
    if (spanId != null) {
      headers['X-Span-Id'] = spanId!;
    }
    return headers;
  }
}
