import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HintDisplayMode {
  olhoDeEditor,
  dicaAberta;

  String get label => switch (this) {
    HintDisplayMode.olhoDeEditor => 'Olho de Editor',
    HintDisplayMode.dicaAberta => 'Dica Aberta',
  };
}

class HintDisplayPreferences {
  HintDisplayPreferences._();

  static final HintDisplayPreferences instance = HintDisplayPreferences._();
  static const String storageKey = 'hint_display_mode_v1';

  final ValueNotifier<HintDisplayMode> modeNotifier =
      ValueNotifier<HintDisplayMode>(HintDisplayMode.olhoDeEditor);
  bool _initialized = false;

  HintDisplayMode get mode => modeNotifier.value;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      modeNotifier.value = _modeFromName(preferences.getString(storageKey));
    } catch (_) {
      modeNotifier.value = HintDisplayMode.olhoDeEditor;
    }
    _initialized = true;
  }

  Future<void> setMode(HintDisplayMode mode) async {
    modeNotifier.value = mode;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(storageKey, mode.name);
    } catch (_) {
      // Ignore preferences issues during tests or unsupported runtimes.
    }
  }
}

HintDisplayMode _modeFromName(String? name) {
  for (final mode in HintDisplayMode.values) {
    if (mode.name == name) {
      return mode;
    }
  }
  return HintDisplayMode.olhoDeEditor;
}
