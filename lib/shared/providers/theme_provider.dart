import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/preferences_service.dart';
import '../../shared/models/user_preferences.dart';

/// Theme mode provider that syncs with user preferences
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  final _preferencesService = PreferencesService.instance;

  Future<void> _loadThemeMode() async {
    try {
      final preferences = await _preferencesService.getPreferences();
      state = preferences.themeMode;
    } catch (e) {
      // Keep default system theme on error
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final currentPrefs = await _preferencesService.getPreferences();
      await _preferencesService.savePreferences(
        currentPrefs.copyWith(themeMode: mode),
      );
    } catch (e) {
      // Revert on error
      await _loadThemeMode();
    }
  }
}
