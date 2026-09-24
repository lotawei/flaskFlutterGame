import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meme_game/core/level/level_model.dart';

/// 关卡 JSON 加载器。
class LevelLoader {
  Future<LevelModel> loadFromAsset(String assetPath) async {
    final String rawJson = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonMap =
        jsonDecode(rawJson) as Map<String, dynamic>;
    return LevelModel.fromJson(jsonMap);
  }

  LevelModel loadFromJsonString(String rawJson) {
    final Map<String, dynamic> jsonMap =
        jsonDecode(rawJson) as Map<String, dynamic>;
    return LevelModel.fromJson(jsonMap);
  }
}
