#ifndef RUNNER_GAMEPAD_PLUGIN_H_
#define RUNNER_GAMEPAD_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

/// Native Windows gamepad bridge using XInput.
/// Supports Xbox controllers (wired/wireless) and PS4 via Steam/DS4Windows.
class GamepadPlugin {
 public:
  static void Register(flutter::PluginRegistrarWindows* registrar);
};

#endif  // RUNNER_GAMEPAD_PLUGIN_H_
