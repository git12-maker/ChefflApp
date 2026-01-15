import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../../services/recipe_service.dart';

/// Central recipe provider to share cached data between home/saved/generate.
final recipeRepositoryProvider = Provider<RecipeService>((ref) {
  return RecipeService.instance;
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

  final RecipeService _repo;

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
