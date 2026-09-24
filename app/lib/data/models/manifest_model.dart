/// 梗包 manifest 数据模型。
class MemePackModel {
  MemePackModel({
    required this.packId,
    required this.name,
    required this.version,
    required this.checksum,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.isDeprecated,
  });

  final String packId;
  final String name;
  final String version;
  final String checksum;
  final String downloadUrl;
  final int sizeBytes;
  final bool isDeprecated;

  factory MemePackModel.fromJson(Map<String, dynamic> json) {
    return MemePackModel(
      packId: json['pack_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      sizeBytes: json['size_bytes'] as int? ?? 0,
      isDeprecated: json['deprecated'] as bool? ?? false,
    );
  }
}

/// Manifest 响应模型。
class ManifestModel {
  ManifestModel({
    required this.schemaVersion,
    required this.serverVersion,
    required this.packs,
  });

  final int schemaVersion;
  final String serverVersion;
  final List<MemePackModel> packs;

  factory ManifestModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPacks = json['packs'] as List<dynamic>? ?? <dynamic>[];
    return ManifestModel(
      schemaVersion: json['schema_version'] as int? ?? 0,
      serverVersion: json['server_version'] as String? ?? '',
      packs: rawPacks
          .whereType<Map<String, dynamic>>()
          .map(MemePackModel.fromJson)
          .toList(),
    );
  }
}

/// API 统一响应包装。
class ApiResponseModel<T> {
  ApiResponseModel({
    required this.code,
    required this.message,
    required this.data,
  });

  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 0;
}
