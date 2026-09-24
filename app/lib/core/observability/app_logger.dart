import 'dart:convert';
import 'dart:developer' as developer;

import 'package:meme_game/core/config/app_config.dart';
import 'package:meme_game/core/observability/trace_context.dart';

/// 统一结构化日志。
class AppLogger {
  AppLogger(this._config);

  final AppConfig _config;

  static const List<String> _levelOrder = <String>[
    'DEBUG',
    'INFO',
    'WARN',
    'ERROR',
  ];

  bool _shouldLog(String level) {
    final int currentIndex = _levelOrder.indexOf(_config.logLevel.toUpperCase());
    final int targetIndex = _levelOrder.indexOf(level.toUpperCase());
    if (currentIndex < 0 || targetIndex < 0) {
      return true;
    }
    return targetIndex >= currentIndex;
  }

  void logEvent({
    required String level,
    required String module,
    required String event,
    required String message,
    TraceContext? traceContext,
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    if (!_shouldLog(level)) {
      return;
    }
    final Map<String, Object?> payload = <String, Object?>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level.toUpperCase(),
      'service': _config.serviceName,
      'module': module,
      'event': event,
      'message': message,
      if (traceContext != null) 'trace_id': traceContext.traceId,
      if (traceContext?.spanId != null) 'span_id': traceContext!.spanId,
      if (extra.isNotEmpty) 'extra': extra,
    };
    final String jsonLine = jsonEncode(payload);
    developer.log(jsonLine, name: module, level: _mapLevel(level));
  }

  void debug({
    required String module,
    required String event,
    required String message,
    TraceContext? traceContext,
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    logEvent(
      level: 'DEBUG',
      module: module,
      event: event,
      message: message,
      traceContext: traceContext,
      extra: extra,
    );
  }

  void info({
    required String module,
    required String event,
    required String message,
    TraceContext? traceContext,
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    logEvent(
      level: 'INFO',
      module: module,
      event: event,
      message: message,
      traceContext: traceContext,
      extra: extra,
    );
  }

  void warn({
    required String module,
    required String event,
    required String message,
    TraceContext? traceContext,
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    logEvent(
      level: 'WARN',
      module: module,
      event: event,
      message: message,
      traceContext: traceContext,
      extra: extra,
    );
  }

  void error({
    required String module,
    required String event,
    required String message,
    TraceContext? traceContext,
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    logEvent(
      level: 'ERROR',
      module: module,
      event: event,
      message: message,
      traceContext: traceContext,
      extra: extra,
    );
  }

  int _mapLevel(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return 1000;
      case 'WARN':
        return 900;
      case 'INFO':
        return 800;
      default:
        return 500;
    }
  }
}
