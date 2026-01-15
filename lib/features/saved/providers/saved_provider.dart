import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/providers/recipe_provider.dart';
import '../../../services/recipe_service.dart';

class SavedState {
  const SavedState({
    this.all = const [],
    this.filtered = const [],
    this.filterFavorites = false,
    this.search = '',
    this.isLoading = false,
    this.error,
  });

  final List<Recipe> all;
  final List<Recipe> filtered;
  final bool filterFavorites;
  final String search;
  final bool isLoading;
  final String? error;

  SavedState copyWith({
    List<Recipe>? all,
    List<Recipe>? filtered,
    bool? filterFavorites,
    String? search,
    bool? isLoading,
    String? error,
  }) {
    return SavedState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      filterFavorites: filterFavorites ?? this.filterFavorites,
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final savedProvider = StateNotifierProvider<SavedNotifier, SavedState>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  return SavedNotifier(repo);
});

class SavedNotifier extends StateNotifier<SavedState> {
  SavedNotifier(this._repo) : super(const SavedState());
    // Don't load immediately - let screen decide when to load

  final RecipeService _repo;
  bool _hasLoaded = false;

  Future<void> load({bool force = false}) async {
    // Prevent duplicate loads
    if (state.isLoading || (_hasLoaded && !force)) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getRecipes();
      _hasLoaded = true;
      state = state.copyWith(
        all: items,
        filtered: _applyFilters(items, state.search, state.filterFavorites),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String value) {
    // Debounce search to avoid excessive filtering
    // Filtering happens synchronously but only when search actually changes
    if (state.search == value) return;
    
    state = state.copyWith(
      search: value,
      filtered: _applyFilters(state.all, value, state.filterFavorites),
    );
  }

  void setFavoritesOnly(bool value) {
    state = state.copyWith(
      filterFavorites: value,
      filtered: _applyFilters(state.all, state.search, value),
    );
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _repo.toggleFavorite(id, isFavorite);
    final updatedAll = state.all
        .map((r) => r.id == id ? r.copyWith(isFavorite: isFavorite) : r)
        .toList();
    state = state.copyWith(
      all: updatedAll,
      filtered:
          _applyFilters(updatedAll, state.search, state.filterFavorites),
    );
  }

  Future<void> delete(String id) async {
    await _repo.deleteRecipe(id);
    final updatedAll = state.all.where((r) => r.id != id).toList();
    state = state.copyWith(
      all: updatedAll,
      filtered:
          _applyFilters(updatedAll, state.search, state.filterFavorites),
    );
  }

  Future<void> refresh() => load(force: true);

  List<Recipe> _applyFilters(
    List<Recipe> items,
    String search,
    bool favoritesOnly,
  ) {
    // Early return for empty filters
    if (search.isEmpty && !favoritesOnly) {
      return items;
    }
    
    // Pre-compute lowercase search term once
    final searchLower = search.isEmpty ? null : search.toLowerCase();
    
    return items.where((r) {
      final matchesSearch = searchLower == null || 
          r.title.toLowerCase().contains(searchLower);
      final matchesFav = !favoritesOnly || r.isFavorite;
      return matchesSearch && matchesFav;
    }).toList();
  }
}
