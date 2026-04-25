import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

typedef TimelineFocusHotkeyHandler = void Function();

abstract class TimelineFocusHotkeyBinding {
  Future<void> register(TimelineFocusHotkeyHandler onTriggered);
  Future<void> unregister();
}

class HotkeyManagerTimelineFocusHotkeyBinding
    implements TimelineFocusHotkeyBinding {
  HotkeyManagerTimelineFocusHotkeyBinding({
    TargetPlatform? platformOverride,
  }) : _platform = platformOverride ?? defaultTargetPlatform;

  final TargetPlatform _platform;
  HotKey? _registeredHotKey;

  @override
  Future<void> register(TimelineFocusHotkeyHandler onTriggered) async {
    await unregister();

    final modifiers = _platform == TargetPlatform.macOS
        ? [HotKeyModifier.meta, HotKeyModifier.shift]
        : [HotKeyModifier.control, HotKeyModifier.shift];
    final hotKey = HotKey(
      key: PhysicalKeyboardKey.space,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (_) => onTriggered(),
    );
    _registeredHotKey = hotKey;
  }

  @override
  Future<void> unregister() async {
    final hotKey = _registeredHotKey;
    if (hotKey == null) return;
    await hotKeyManager.unregister(hotKey);
    _registeredHotKey = null;
  }
}
