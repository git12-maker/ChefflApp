import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/recipe_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../services/credits_service.dart';

class ProfileState {
  const ProfileState({
    this.totalRecipes = 0,
    this.favoritesCount = 0,
    this.recipesThisMonth = 0,
    this.credits = 0,
    this.isLoading = false,
    this.error,
  });

  final int totalRecipes;
  final int favoritesCount;
  final int recipesThisMonth;
  final int credits;
  final bool isLoading;
  final String? error;

  ProfileState copyWith({
    int? totalRecipes,
    int? favoritesCount,
    int? recipesThisMonth,
    int? credits,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      totalRecipes: totalRecipes ?? this.totalRecipes,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      recipesThisMonth: recipesThisMonth ?? this.recipesThisMonth,
      credits: credits ?? this.credits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ref) : super(const ProfileState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final adapter = _ref.read(recipeRepositoryProvider);
      final stats = await adapter.getStats();
      final credits = await CreditsService.instance.getAvailableCredits();
      state = state.copyWith(
        totalRecipes: stats['total'] ?? 0,
        favoritesCount: stats['favorites'] ?? 0,
        recipesThisMonth: stats['thisMonth'] ?? 0,
        credits: credits,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshStats() async {
    try {
      final adapter = _ref.read(recipeRepositoryProvider);
      final stats = await adapter.getStats();
      final credits = await CreditsService.instance.getAvailableCredits();
      state = state.copyWith(
        totalRecipes: stats['total'] ?? 0,
        favoritesCount: stats['favorites'] ?? 0,
        recipesThisMonth: stats['thisMonth'] ?? 0,
        credits: credits,
      );
    } catch (e) {
      // Keep existing values on error
    }
  }

  Future<void> logout() async {
    await SupabaseService.client.auth.signOut();
  }
}
