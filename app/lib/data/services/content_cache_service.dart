import 'dart:convert';
import 'dart:io';

import 'package:meme_game/core/observability/app_logger.dart';
import 'package:path_provider/path_provider.dart';

/// 梗包/关卡本地缓存。
class ContentCacheService {
  ContentCacheService({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  Future<Directory> _cacheRoot() async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final Directory cacheDir = Directory('${baseDir.path}/meme_cache');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    return cacheDir;
  }

  Future<File?> readLevelFile(String levelId) async {
    final Directory root = await _cacheRoot();
    final File file = File('${root.path}/levels/$levelId.json');
    if (!file.existsSync()) {
      return null;
    }
    return file;
  }

  Future<void> saveLevel({
    required String levelId,
    required String rawJson,
  }) async {
    final Directory root = await _cacheRoot();
    final Directory levelDir = Directory('${root.path}/levels');
    if (!levelDir.existsSync()) {
      levelDir.createSync(recursive: true);
    }
    final File file = File('${levelDir.path}/$levelId.json');
    await file.writeAsString(rawJson);
    _logger.info(
      module: 'data.cache',
      event: 'content.level.cache.saved',
      message: '关卡已写入本地缓存',
      extra: <String, Object?>{'level_id': levelId, 'path': file.path},
    );
  }

  Future<void> saveManifest(String rawJson) async {
    final Directory root = await _cacheRoot();
    final File file = File('${root.path}/manifest.json');
    await file.writeAsString(rawJson);
  }

  Future<String?> readManifest() async {
    final Directory root = await _cacheRoot();
    final File file = File('${root.path}/manifest.json');
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsStringSync();
  }
}

/// 将 Map 编码为 JSON 字符串。
String encodeLevelJson(Map<String, dynamic> data) {
  return jsonEncode(data);
}

/// 解析 JSON 字符串。
Map<String, dynamic> decodeLevelJson(String rawJson) {
  return jsonDecode(rawJson) as Map<String, dynamic>;
}
