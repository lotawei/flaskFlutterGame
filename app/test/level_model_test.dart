import 'package:flutter_test/flutter_test.dart';
import 'package:meme_game/core/level/level_loader.dart';

void main() {
  test('关卡 JSON 可解析敌人配置', () async {
    const String rawJson = '''
    {
      "level_id": "test",
      "name": "test",
      "tile_size": 32,
      "width_tiles": 10,
      "height_tiles": 10,
      "player_spawn": {"x": 1, "y": 1},
      "platforms": [],
      "coins": [],
      "enemies": [{"x": 5, "y": 3, "patrol_left": 1, "patrol_right": 2}],
      "goal": {"x": 8, "y": 1},
      "tip_text": "tip"
    }
    ''';
    final level = LevelLoader().loadFromJsonString(rawJson);
    expect(level.enemies.length, 1);
    expect(level.enemies.first.patrolLeft, 1);
    expect(level.enemies.first.patrolRight, 2);
  });
}
