import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/providers/recipe_provider.dart';

class HomeState {
  const HomeState({
    this.recents = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Recipe> recents;
  final bool isLoading;
  final String? error;

  HomeState copyWith({
    List<Recipe>? recents,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      recents: recents ?? this.recents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  return HomeNotifier(repo);
});

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._repo) : super(const HomeState()) {
    // Don't load immediately - let screen decide when to load
    // This prevents blocking app startup
  }

  final RecipeServiceAdapter _repo;
  bool _hasLoaded = false;

  Future<void> loadRecents({bool force = false}) async {
    // Prevent duplicate loads
    if (state.isLoading || (_hasLoaded && !force)) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getRecipes();
      final recents = items.take(10).toList();
      _hasLoaded = true;
      state = state.copyWith(recents: recents, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadRecents(force: true);
}
