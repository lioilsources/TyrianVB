#include "gamepad_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <Xinput.h>

#pragma comment(lib, "xinput.lib")

#include <memory>

static void HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() != "poll") {
    result->NotImplemented();
    return;
  }

  flutter::EncodableList controllers;

  for (DWORD i = 0; i < XUSER_MAX_COUNT; i++) {
    XINPUT_STATE state;
    ZeroMemory(&state, sizeof(XINPUT_STATE));

    if (XInputGetState(i, &state) != ERROR_SUCCESS) continue;

    auto& gp = state.Gamepad;

    // Normalize stick values to -1.0 .. 1.0
    auto normalize = [](SHORT val, SHORT deadzone) -> double {
      if (val > deadzone) return (val - deadzone) / (32767.0 - deadzone);
      if (val < -deadzone) return (val + deadzone) / (32767.0 - deadzone);
      return 0.0;
    };

    double lx = normalize(gp.sThumbLX, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
    double ly = -normalize(gp.sThumbLY, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
    double rx = normalize(gp.sThumbRX, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);
    double ry = -normalize(gp.sThumbRY, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);
    double lt = gp.bLeftTrigger / 255.0;
    double rt = gp.bRightTrigger / 255.0;

    flutter::EncodableMap pad;
    pad[flutter::EncodableValue("lx")] = flutter::EncodableValue(lx);
    pad[flutter::EncodableValue("ly")] = flutter::EncodableValue(ly);
    pad[flutter::EncodableValue("rx")] = flutter::EncodableValue(rx);
    pad[flutter::EncodableValue("ry")] = flutter::EncodableValue(ry);
    pad[flutter::EncodableValue("a")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_A) != 0);
    pad[flutter::EncodableValue("b")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_B) != 0);
    pad[flutter::EncodableValue("x")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_X) != 0);
    pad[flutter::EncodableValue("y")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_Y) != 0);
    pad[flutter::EncodableValue("lb")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER) != 0);
    pad[flutter::EncodableValue("rb")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER) != 0);
    pad[flutter::EncodableValue("lt")] = flutter::EncodableValue(lt);
    pad[flutter::EncodableValue("rt")] = flutter::EncodableValue(rt);
    pad[flutter::EncodableValue("du")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_DPAD_UP) != 0);
    pad[flutter::EncodableValue("dd")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_DPAD_DOWN) != 0);
    pad[flutter::EncodableValue("dl")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_DPAD_LEFT) != 0);
    pad[flutter::EncodableValue("dr")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT) != 0);
    pad[flutter::EncodableValue("start")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_START) != 0);
    pad[flutter::EncodableValue("back")] = flutter::EncodableValue((gp.wButtons & XINPUT_GAMEPAD_BACK) != 0);

    controllers.push_back(flutter::EncodableValue(pad));
  }

  result->Success(flutter::EncodableValue(controllers));
}

// Prevent registrar & channel from being destroyed when the function returns.
static flutter::PluginRegistrarWindows* g_registrar = nullptr;
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_channel;

void GamepadPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar_ref) {
  g_registrar = new flutter::PluginRegistrarWindows(registrar_ref);
  g_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      g_registrar->messenger(), "com.tyrian/gamepad",
      &flutter::StandardMethodCodec::GetInstance());

  g_channel->SetMethodCallHandler(HandleMethodCall);
}
