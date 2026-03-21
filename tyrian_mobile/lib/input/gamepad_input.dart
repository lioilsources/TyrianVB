import 'dart:io';
import 'package:flutter/services.dart';

/// Cross-platform gamepad abstraction using native MethodChannel.
/// Polls controller state each frame via [poll()].
class GamepadInput {
  static const _channel = MethodChannel('com.tyrian/gamepad');

  /// Per-controller state. Index 0 = first connected controller.
  final List<GamepadState> controllers = [];

  /// True if at least one controller is connected.
  bool get isConnected => controllers.isNotEmpty;

  /// Convenience: first controller (or empty state).
  GamepadState get primary =>
      controllers.isNotEmpty ? controllers[0] : GamepadState.empty;

  /// Second controller for local co-op (or empty).
  GamepadState get secondary =>
      controllers.length > 1 ? controllers[1] : GamepadState.empty;

  /// Poll native API for current controller states.
  Future<void> poll() async {
    if (!Platform.isMacOS && !Platform.isWindows) return;
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('poll');
      if (result == null) {
        controllers.clear();
        return;
      }
      controllers.clear();
      for (final raw in result) {
        if (raw is Map) {
          controllers.add(GamepadState.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    } on MissingPluginException {
      // Native side not available — ignore
    } catch (_) {
      controllers.clear();
    }
  }

  /// Apply deadzone to an analog value.
  static double deadzone(double v, {double dz = 0.15}) {
    if (v.abs() < dz) return 0.0;
    return (v.abs() - dz) / (1.0 - dz) * v.sign;
  }
}

/// State of a single gamepad controller.
class GamepadState {
  final double leftStickX;  // -1.0 to 1.0
  final double leftStickY;  // -1.0 to 1.0
  final double rightStickX;
  final double rightStickY;
  final bool buttonA;       // Cross (PS) / A (Xbox)
  final bool buttonB;       // Circle (PS) / B (Xbox)
  final bool buttonX;       // Square (PS) / X (Xbox)
  final bool buttonY;       // Triangle (PS) / Y (Xbox)
  final bool leftShoulder;  // L1 / LB
  final bool rightShoulder; // R1 / RB
  final double leftTrigger;  // L2 / LT (0.0 to 1.0)
  final double rightTrigger; // R2 / RT (0.0 to 1.0)
  final bool dpadUp;
  final bool dpadDown;
  final bool dpadLeft;
  final bool dpadRight;
  final bool start;         // Options (PS) / Menu (Xbox)
  final bool back;          // Share/Create (PS) / View (Xbox)

  const GamepadState({
    this.leftStickX = 0,
    this.leftStickY = 0,
    this.rightStickX = 0,
    this.rightStickY = 0,
    this.buttonA = false,
    this.buttonB = false,
    this.buttonX = false,
    this.buttonY = false,
    this.leftShoulder = false,
    this.rightShoulder = false,
    this.leftTrigger = 0,
    this.rightTrigger = 0,
    this.dpadUp = false,
    this.dpadDown = false,
    this.dpadLeft = false,
    this.dpadRight = false,
    this.start = false,
    this.back = false,
  });

  static const GamepadState empty = GamepadState();

  /// Fire = R2 trigger > 0.3 OR right shoulder OR button A/X
  bool get fire => rightTrigger > 0.3 || rightShoulder || buttonA || buttonX;

  /// Pause = Start/Options button
  bool get pause => start;

  factory GamepadState.fromMap(Map<String, dynamic> m) {
    return GamepadState(
      leftStickX: (m['lx'] as num?)?.toDouble() ?? 0,
      leftStickY: (m['ly'] as num?)?.toDouble() ?? 0,
      rightStickX: (m['rx'] as num?)?.toDouble() ?? 0,
      rightStickY: (m['ry'] as num?)?.toDouble() ?? 0,
      buttonA: m['a'] == true,
      buttonB: m['b'] == true,
      buttonX: m['x'] == true,
      buttonY: m['y'] == true,
      leftShoulder: m['lb'] == true,
      rightShoulder: m['rb'] == true,
      leftTrigger: (m['lt'] as num?)?.toDouble() ?? 0,
      rightTrigger: (m['rt'] as num?)?.toDouble() ?? 0,
      dpadUp: m['du'] == true,
      dpadDown: m['dd'] == true,
      dpadLeft: m['dl'] == true,
      dpadRight: m['dr'] == true,
      start: m['start'] == true,
      back: m['back'] == true,
    );
  }
}
