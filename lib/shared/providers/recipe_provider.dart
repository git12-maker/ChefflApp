import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../../services/recipe_service_simple.dart';

/// Adapter for RecipeServiceSimple to match expected interface
class RecipeServiceAdapter {
  RecipeServiceAdapter(this._service);
  final RecipeServiceSimple _service;

  Future<List<Recipe>> getRecipes() => _service.getMyRecipes();

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _service.toggleFavorite(id);
  }

  Future<void> deleteRecipe(String id) => _service.softDeleteRecipe(id);

  Future<Map<String, int>> getStats() => _service.getStats();
}

/// Central recipe provider - uses simplified service
final recipeRepositoryProvider = Provider<RecipeServiceAdapter>((ref) {
  return RecipeServiceAdapter(RecipeServiceSimple.instance);
});

/// Cache state for recipes.
class RecipeCacheState {
  const RecipeCacheState({
    this.recipes = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Recipe> recipes;
  final bool isLoading;
  final String? error;

  RecipeCacheState copyWith({
    List<Recipe>? recipes,
    bool? isLoading,
    String? error,
  }) {
    return RecipeCacheState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final recipeCacheProvider =
    StateNotifierProvider<RecipeCacheNotifier, RecipeCacheState>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  return RecipeCacheNotifier(repo);
});

class RecipeCacheNotifier extends StateNotifier<RecipeCacheState> {
  RecipeCacheNotifier(this._repo) : super(const RecipeCacheState());

  final RecipeServiceAdapter _repo;

  Future<void> loadAll({bool force = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getRecipes();
      state = state.copyWith(recipes: items, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => loadAll(force: true);

  Future<void> delete(String id) async {
    try {
      await _repo.deleteRecipe(id);
      state = state.copyWith(
        recipes: state.recipes.where((r) => r.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      await _repo.toggleFavorite(id, isFavorite);
      state = state.copyWith(
        recipes: state.recipes
            .map((r) =>
                r.id == id ? r.copyWith(isFavorite: isFavorite) : r)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
