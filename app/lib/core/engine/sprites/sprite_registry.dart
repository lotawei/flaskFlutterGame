import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'package:meme_game/core/engine/sprites/sprite_sheet_meta.dart';

/// 游戏精灵资源注册与加载。
class SpriteRegistry {
  static const String _bundleRoot = 'assets/images/';

  final Map<String, SpriteSheetMeta> _metaMap = <String, SpriteSheetMeta>{};
  final Map<String, ui.Image> _imageMap = <String, ui.Image>{};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> preloadAllAssets() async {
    if (_isLoaded) {
      return;
    }
    const List<String> imagePaths = <String>[
      'sprites/player/player_sheet.png',
      'sprites/collectibles/coin_sheet.png',
      'sprites/environment/tile_ground.png',
      'sprites/environment/tile_platform.png',
      'sprites/environment/tile_ceiling.png',
      'sprites/environment/gravity_portal_sheet.png',
      'sprites/collectibles/goal_flag.png',
      'sprites/enemies/enemy_basic_sheet.png',
      'sprites/fx/fx_dust_sheet.png',
      'sprites/fx/fx_coin_burst_sheet.png',
      'backgrounds/bg_sky.png',
      'ui/bubbles/ui_meme_bubble.png',
      'ui/banners/ui_result_banner.png',
    ];
    for (final String path in imagePaths) {
      await Flame.images.load(path);
      _imageMap[_mapKey(path)] = Flame.images.fromCache(path);
    }
    _metaMap['player'] = await _loadMeta(
      '${_bundleRoot}sprites/player/player_sheet.json',
    );
    _metaMap['coin'] = await _loadMeta(
      '${_bundleRoot}sprites/collectibles/coin_sheet.json',
    );
    _metaMap['enemy'] = await _loadMeta(
      '${_bundleRoot}sprites/enemies/enemy_basic_sheet.json',
    );
    _metaMap['gravity_portal'] = await _loadMeta(
      '${_bundleRoot}sprites/environment/gravity_portal_sheet.json',
    );
    _metaMap['fx_dust'] = await _loadMeta(
      '${_bundleRoot}sprites/fx/fx_dust_sheet.json',
    );
    _metaMap['fx_coin_burst'] = await _loadMeta(
      '${_bundleRoot}sprites/fx/fx_coin_burst_sheet.json',
    );
    _isLoaded = true;
  }

  @Deprecated('Use preloadAllAssets')
  Future<void> preloadP0Assets() => preloadAllAssets();

  String _mapKey(String path) {
    if (path.contains('player_sheet')) {
      return 'player';
    }
    if (path.contains('coin_sheet')) {
      return 'coin';
    }
    if (path.contains('enemy_basic')) {
      return 'enemy';
    }
    if (path.contains('tile_ground')) {
      return 'tile_ground';
    }
    if (path.contains('tile_platform')) {
      return 'tile_platform';
    }
    if (path.contains('tile_ceiling')) {
      return 'tile_ceiling';
    }
    if (path.contains('gravity_portal')) {
      return 'gravity_portal';
    }
    if (path.contains('goal_flag')) {
      return 'goal_flag';
    }
    if (path.contains('bg_sky')) {
      return 'bg_sky';
    }
    if (path.contains('fx_dust')) {
      return 'fx_dust';
    }
    if (path.contains('fx_coin_burst')) {
      return 'fx_coin_burst';
    }
    if (path.contains('ui_meme_bubble')) {
      return 'ui_meme_bubble';
    }
    if (path.contains('ui_result_banner')) {
      return 'ui_result_banner';
    }
    return path;
  }

  Future<SpriteSheetMeta> _loadMeta(String assetPath) async {
    final String rawJson = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonMap =
        jsonDecode(rawJson) as Map<String, dynamic>;
    return SpriteSheetMeta.fromJson(jsonMap);
  }

  SpriteAnimation? buildAnimation(String sheetKey, String animationKey) {
    final ui.Image? image = _imageMap[sheetKey];
    final SpriteSheetMeta? meta = _metaMap[sheetKey];
    if (image == null || meta == null) {
      return null;
    }
    final SpriteAnimationMeta? animationMeta = meta.animations[animationKey];
    if (animationMeta == null) {
      return null;
    }
    final SpriteSheet sheet = SpriteSheet(
      image: image,
      srcSize: Vector2(meta.frameWidth.toDouble(), meta.frameHeight.toDouble()),
    );
    return sheet.createAnimation(
      row: animationMeta.row,
      stepTime: 1 / animationMeta.fps,
      to: animationMeta.frameCount,
      loop: animationMeta.loop,
    );
  }

  Sprite? buildSprite(String imageKey) {
    final ui.Image? image = _imageMap[imageKey];
    if (image == null) {
      return null;
    }
    return Sprite(image);
  }
}
