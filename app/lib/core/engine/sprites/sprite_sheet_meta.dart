/// 精灵表元数据模型。
class SpriteSheetMeta {
  SpriteSheetMeta({
    required this.sheet,
    required this.frameWidth,
    required this.frameHeight,
    required this.anchorX,
    required this.anchorY,
    required this.animations,
  });

  final String sheet;
  final int frameWidth;
  final int frameHeight;
  final double anchorX;
  final double anchorY;
  final Map<String, SpriteAnimationMeta> animations;

  factory SpriteSheetMeta.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? anchor =
        json['anchor'] as Map<String, dynamic>?;
    final Map<String, dynamic>? rawAnimations =
        json['animations'] as Map<String, dynamic>?;
    final Map<String, SpriteAnimationMeta> animations =
        <String, SpriteAnimationMeta>{};
    rawAnimations?.forEach((String key, dynamic value) {
      if (value is Map<String, dynamic>) {
        animations[key] = SpriteAnimationMeta.fromJson(value);
      }
    });
    return SpriteSheetMeta(
      sheet: json['sheet'] as String? ?? '',
      frameWidth: json['frameWidth'] as int? ?? 32,
      frameHeight: json['frameHeight'] as int? ?? 32,
      anchorX: (anchor?['x'] as num?)?.toDouble() ?? 0.5,
      anchorY: (anchor?['y'] as num?)?.toDouble() ?? 1.0,
      animations: animations,
    );
  }
}

/// 单段动画元数据。
class SpriteAnimationMeta {
  SpriteAnimationMeta({
    required this.row,
    required this.frameCount,
    required this.fps,
    required this.loop,
  });

  final int row;
  final int frameCount;
  final int fps;
  final bool loop;

  factory SpriteAnimationMeta.fromJson(Map<String, dynamic> json) {
    return SpriteAnimationMeta(
      row: json['row'] as int? ?? 0,
      frameCount: json['frameCount'] as int? ?? 1,
      fps: json['fps'] as int? ?? 8,
      loop: json['loop'] as bool? ?? true,
    );
  }
}
