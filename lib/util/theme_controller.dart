import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme mode selection, persisted across launches.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  static const String _prefsKey = 'theme_mode';

  /// Load the saved mode (no-op if there's nothing stored). Safe to call
  /// before [runApp].
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      value = _decode(raw);
    } catch (_) {
      // Storage failures shouldn't block app start; keep system default.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _encode(mode));
    } catch (_) {
      // Best-effort persistence; in-memory value already updated.
    }
  }

  /// Cycle System -> Light -> Dark -> System for a single tap toggle.
  Future<void> cycle() => setMode(switch (value) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      });

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

/// Single shared instance used by `MaterialApp` and the settings toggle.
final ThemeController themeController = ThemeController();
