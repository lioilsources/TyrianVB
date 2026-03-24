#ifndef RUNNER_GAMEPAD_PLUGIN_H_
#define RUNNER_GAMEPAD_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Native Windows gamepad bridge using XInput.
void GamepadPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#ifdef __cplusplus
}
#endif

#endif  // RUNNER_GAMEPAD_PLUGIN_H_
