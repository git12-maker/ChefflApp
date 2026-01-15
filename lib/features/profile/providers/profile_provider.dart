import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../services/preferences_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/recipe_service.dart';

class ProfileState {
  const ProfileState({
    this.preferences = const UserPreferences(),
    this.totalRecipes = 0,
    this.favoritesCount = 0,
    this.recipesThisMonth = 0,
    this.isLoading = false,
    this.error,
  });

  final UserPreferences preferences;
  final int totalRecipes;
  final int favoritesCount;
  final int recipesThisMonth;
  final bool isLoading;
  final String? error;

  ProfileState copyWith({
    UserPreferences? preferences,
    int? totalRecipes,
    int? favoritesCount,
    int? recipesThisMonth,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      preferences: preferences ?? this.preferences,
      totalRecipes: totalRecipes ?? this.totalRecipes,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      recipesThisMonth: recipesThisMonth ?? this.recipesThisMonth,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState()) {
    load();
  }

  final _preferencesService = PreferencesService.instance;
  final _recipeService = RecipeService.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final preferences = await _preferencesService.getPreferences();
      final stats = await _loadStats();
      
      state = state.copyWith(
        preferences: preferences,
        totalRecipes: stats['total'] ?? 0,
        favoritesCount: stats['favorites'] ?? 0,
        recipesThisMonth: stats['thisMonth'] ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, int>> _loadStats() async {
    try {
      // Use optimized stats method from RecipeService
      // This uses database queries instead of loading all recipes
      return await _recipeService.getStats();
    } catch (e) {
      return {'total': 0, 'favorites': 0, 'thisMonth': 0};
    }
  }

  Future<void> updateDietaryPreferences(List<String> preferences) async {
    try {
      final updated = state.preferences.copyWith(
        dietaryPreferences: preferences,
      );
      await _preferencesService.savePreferences(updated);
      // Update state directly (no need to reload - we know what we saved)
      state = state.copyWith(preferences: updated);
    } catch (e) {
      print('Error updating dietary preferences: $e');
      rethrow;
    }
  }

  Future<void> updateDefaultServings(int servings) async {
    try {
      final updated = state.preferences.copyWith(defaultServings: servings);
      await _preferencesService.savePreferences(updated);
      // Update state directly (no need to reload - we know what we saved)
      state = state.copyWith(preferences: updated);
    } catch (e) {
      print('Error updating default servings: $e');
      rethrow;
    }
  }

  Future<void> updatePreferredCuisines(List<String> cuisines) async {
    try {
      final updated = state.preferences.copyWith(
        preferredCuisines: cuisines,
      );
      await _preferencesService.savePreferences(updated);
      // Update state directly (no need to reload - we know what we saved)
      state = state.copyWith(preferences: updated);
    } catch (e) {
      print('Error updating preferred cuisines: $e');
      rethrow;
    }
  }

  Future<void> updateMeasurementUnit(MeasurementUnit unit) async {
    try {
      final updated = state.preferences.copyWith(measurementUnit: unit);
      await _preferencesService.savePreferences(updated);
      // Update state directly (no need to reload - we know what we saved)
      state = state.copyWith(preferences: updated);
    } catch (e) {
      print('Error updating measurement unit: $e');
      rethrow;
    }
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    try {
      final updated = state.preferences.copyWith(themeMode: themeMode);
      await _preferencesService.savePreferences(updated);
      // Update state directly (no need to reload - we know what we saved)
      state = state.copyWith(preferences: updated);
    } catch (e) {
      print('Error updating theme mode: $e');
      rethrow;
    }
  }

  /// Refresh stats only (without reloading preferences)
  /// Useful for updating counts after recipes are added/deleted
  Future<void> refreshStats() async {
    try {
      final stats = await _loadStats();
      state = state.copyWith(
        totalRecipes: stats['total'] ?? 0,
        favoritesCount: stats['favorites'] ?? 0,
        recipesThisMonth: stats['thisMonth'] ?? 0,
      );
    } catch (e) {
      // Don't update state on error, keep existing values
    }
  }

  Future<void> logout() async {
    await SupabaseService.client.auth.signOut();
  }
}
