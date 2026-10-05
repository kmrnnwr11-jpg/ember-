import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeMode = 'app_theme_mode';

/// Light, dark or the device's own setting: dark by default, the user's
/// choice is saved.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(_kThemeMode);
      final saved = ThemeMode.values.where((m) => m.name == name).firstOrNull;
      if (saved != null) state = saved;
    } catch (_) {
      // keep the default
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(_kThemeMode, mode.name);
    } catch (_) {}
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
