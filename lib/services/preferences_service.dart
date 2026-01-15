import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/user_preferences.dart';
import 'supabase_service.dart';

/// Service for managing user preferences
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Get user preferences
  Future<UserPreferences> getPreferences() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const UserPreferences(); // Return defaults if not authenticated
    }

    try {
      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        return await _createDefaultPreferences(user.id);
      }

      // Try to get preferences from JSONB column first, fallback to individual columns
      if (response['preferences'] != null) {
        final prefsJson = response['preferences'] as Map<String, dynamic>;
        return UserPreferences.fromJson(prefsJson);
      }

      // Fallback to individual columns for backward compatibility
      return UserPreferences(
        dietaryPreferences: (response['dietary_restrictions'] as Map<String, dynamic>?)
                ?.keys
                .toList() ??
            [],
        defaultServings: response['default_servings'] as int? ?? 2,
        preferredCuisines: (response['favorite_cuisines'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        measurementUnit: MeasurementUnit.fromString(
          response['measurement_unit'] as String? ?? 'metric',
        ),
        themeMode: _themeModeFromString(
          response['theme_mode'] as String? ?? 'system',
        ),
      );
    } catch (e) {
      print('Error loading preferences: $e');
      return const UserPreferences(); // Return defaults on error
    }
  }

  /// Save user preferences
  Future<void> savePreferences(UserPreferences preferences) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final prefsJson = preferences.toJson();

      // Update or insert preferences
      await _client.from('user_preferences').upsert({
        'user_id': user.id,
        'preferences': prefsJson,
        'measurement_unit': prefsJson['measurementUnit'],
        'theme_mode': prefsJson['themeMode'],
        'default_servings': preferences.defaultServings,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save preferences: $e');
    }
  }

  /// Update a single preference field
  Future<void> updatePreference<T>({
    required String key,
    required T value,
  }) async {
    final current = await getPreferences();
    final updated = _updatePreferenceField(current, key, value);
    await savePreferences(updated);
  }

  UserPreferences _updatePreferenceField<T>(
    UserPreferences current,
    String key,
    T value,
  ) {
    switch (key) {
      case 'dietaryPreferences':
        return current.copyWith(
          dietaryPreferences: value as List<String>,
        );
      case 'defaultServings':
        return current.copyWith(defaultServings: value as int);
      case 'preferredCuisines':
        return current.copyWith(
          preferredCuisines: value as List<String>,
        );
      case 'measurementUnit':
        return current.copyWith(
          measurementUnit: value as MeasurementUnit,
        );
      case 'themeMode':
        return current.copyWith(themeMode: value as ThemeMode);
      default:
        return current;
    }
  }

  Future<UserPreferences> _createDefaultPreferences(String userId) async {
    const defaults = UserPreferences();
    await _client.from('user_preferences').insert({
      'user_id': userId,
      'preferences': defaults.toJson(),
      'measurement_unit': 'metric',
      'theme_mode': 'system',
      'default_servings': 2,
    });
    return defaults;
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
