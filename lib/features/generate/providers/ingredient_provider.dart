import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../../../shared/models/ingredient.dart';

// Re-export types for convenience
export '../../../services/culinary_intelligence_service.dart' show CompositionAnalysis, IngredientSuggestion;

/// State for ingredient selection and smart suggestions
class IngredientSelectionState {
  const IngredientSelectionState({
    this.allIngredients = const [],
    this.categorizedIngredients = const {},
    this.searchResults = const [],
    this.analysis,
    this.isLoading = false,
    this.error,
  });

  final List<Ingredient> allIngredients;
  final Map<String, List<Ingredient>> categorizedIngredients;
  final List<Ingredient> searchResults;
  final CompositionAnalysis? analysis;
  final bool isLoading;
  final String? error;

  IngredientSelectionState copyWith({
    List<Ingredient>? allIngredients,
    Map<String, List<Ingredient>>? categorizedIngredients,
    List<Ingredient>? searchResults,
    CompositionAnalysis? analysis,
    bool? isLoading,
    String? error,
  }) {
    return IngredientSelectionState(
      allIngredients: allIngredients ?? this.allIngredients,
      categorizedIngredients: categorizedIngredients ?? this.categorizedIngredients,
      searchResults: searchResults ?? this.searchResults,
      analysis: analysis ?? this.analysis,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for ingredient selection and culinary intelligence
final ingredientProvider =
    StateNotifierProvider<IngredientNotifier, IngredientSelectionState>((ref) {
  return IngredientNotifier();
});

class IngredientNotifier extends StateNotifier<IngredientSelectionState> {
  IngredientNotifier() : super(const IngredientSelectionState()) {
    _loadIngredients();
  }

  final _culinaryService = CulinaryIntelligenceService.instance;

  Future<void> _loadIngredients() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final all = await _culinaryService.getAllIngredients();
      final categorized = await _culinaryService.getIngredientsByCategory();
      
      state = state.copyWith(
        allIngredients: all,
        categorizedIngredients: categorized,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load ingredients: $e',
      );
    }
  }

  /// Reload ingredients from database
  Future<void> refresh() async {
    _culinaryService.clearCache();
    await _loadIngredients();
  }

  /// Search ingredients by name
  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }
    
    final results = await _culinaryService.searchIngredients(query);
    state = state.copyWith(searchResults: results);
  }

  /// Analyze the current ingredient selection
  Future<void> analyzeSelection(List<String> selectedIngredients) async {
    if (selectedIngredients.isEmpty) {
      state = state.copyWith(analysis: null);
      return;
    }
    
    try {
      final analysis = await _culinaryService.analyzeComposition(selectedIngredients);
      state = state.copyWith(analysis: analysis);
    } catch (e) {
      state = state.copyWith(error: 'Analysis failed: $e');
    }
  }

  /// Get smart suggestions for current selection
  Future<List<IngredientSuggestion>> getSuggestions(List<String> currentIngredients) async {
    return await _culinaryService.getSuggestions(currentIngredients);
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
