/// 玩家输入状态（键盘 + 触控共享）。
class GameInputState {
  bool moveLeft = false;
  bool moveRight = false;
  bool jumpPressed = false;
  bool jumpHeld = false;

  void reset() {
    moveLeft = false;
    moveRight = false;
    jumpPressed = false;
    jumpHeld = false;
  }
}
