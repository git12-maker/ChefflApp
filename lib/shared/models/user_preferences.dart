import 'package:flutter/material.dart';

/// User preferences model
class UserPreferences {
  const UserPreferences({
    this.dietaryPreferences = const [],
    this.defaultServings = 2,
    this.preferredCuisines = const [],
    this.measurementUnit = MeasurementUnit.metric,
    this.themeMode = ThemeMode.system,
  });

  final List<String> dietaryPreferences;
  final int defaultServings;
  final List<String> preferredCuisines;
  final MeasurementUnit measurementUnit;
  final ThemeMode themeMode;

  UserPreferences copyWith({
    List<String>? dietaryPreferences,
    int? defaultServings,
    List<String>? preferredCuisines,
    MeasurementUnit? measurementUnit,
    ThemeMode? themeMode,
  }) {
    return UserPreferences(
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      defaultServings: defaultServings ?? this.defaultServings,
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      dietaryPreferences: (json['dietaryPreferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      defaultServings: json['defaultServings'] as int? ?? 2,
      preferredCuisines: (json['preferredCuisines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      measurementUnit: MeasurementUnit.fromString(
        json['measurementUnit'] as String? ?? 'metric',
      ),
      themeMode: _themeModeFromString(
        json['themeMode'] as String? ?? 'system',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dietaryPreferences': dietaryPreferences,
      'defaultServings': defaultServings,
      'preferredCuisines': preferredCuisines,
      'measurementUnit': measurementUnit.toString().split('.').last,
      'themeMode': _themeModeToString(themeMode),
    };
  }

  static ThemeMode _themeModeFromString(String value) {
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

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

enum MeasurementUnit {
  metric,
  imperial;

  static MeasurementUnit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'imperial':
        return MeasurementUnit.imperial;
      case 'metric':
      default:
        return MeasurementUnit.metric;
    }
  }

  String get displayName {
    switch (this) {
      case MeasurementUnit.metric:
        return 'Metric';
      case MeasurementUnit.imperial:
        return 'Imperial';
    }
  }
}
