import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../services/ingredient_conversion_service.dart';
import '../../../services/preferences_service.dart';

/// State for recipe display (servings, measurement unit)
class RecipeDisplayState {
  const RecipeDisplayState({
    required this.recipe,
    required this.displayServings,
    required this.measurementUnit,
    this.convertedIngredients,
  });

  final Recipe recipe;
  final int displayServings;
  final MeasurementUnit measurementUnit;
  final List<RecipeIngredient>? convertedIngredients;

  RecipeDisplayState copyWith({
    Recipe? recipe,
    int? displayServings,
    MeasurementUnit? measurementUnit,
    List<RecipeIngredient>? convertedIngredients,
  }) {
    return RecipeDisplayState(
      recipe: recipe ?? this.recipe,
      displayServings: displayServings ?? this.displayServings,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      convertedIngredients: convertedIngredients ?? this.convertedIngredients,
    );
  }

  /// Get ingredients (converted if needed, otherwise original)
  List<RecipeIngredient> get ingredients {
    return convertedIngredients ?? recipe.ingredients;
  }

  /// Get original servings from recipe
  int get originalServings => recipe.servings ?? displayServings;
}

/// Provider for recipe display state
final recipeDisplayProvider = StateNotifierProvider.family<RecipeDisplayNotifier, RecipeDisplayState, Recipe>((ref, recipe) {
  return RecipeDisplayNotifier(recipe);
});

class RecipeDisplayNotifier extends StateNotifier<RecipeDisplayState> {
  RecipeDisplayNotifier(Recipe recipe) : super(RecipeDisplayState(
    recipe: recipe,
    displayServings: recipe.servings ?? 2,
    measurementUnit: MeasurementUnit.metric, // Will be loaded from preferences
  )) {
    _loadUserPreferences();
  }

  final _conversionService = IngredientConversionService.instance;
  final _preferencesService = PreferencesService.instance;

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await _preferencesService.getPreferences();
      final originalUnit = prefs.measurementUnit;
      
      state = state.copyWith(
        measurementUnit: originalUnit,
      );
      
      // Convert ingredients if needed
      _updateConvertedIngredients();
    } catch (e) {
      // Keep default metric unit
    }
  }

  void setServings(int servings) {
    if (servings < 1) return;
    
    state = state.copyWith(displayServings: servings);
    _updateConvertedIngredients();
  }

  void setMeasurementUnit(MeasurementUnit unit) {
    if (state.measurementUnit == unit) return; // No change needed
    
    // Update unit first
    state = state.copyWith(measurementUnit: unit);
    
    // Force recalculation by clearing and recalculating
    _updateConvertedIngredients();
  }

  void _updateConvertedIngredients() {
    final originalServings = state.originalServings;
    final displayServings = state.displayServings;
    const originalUnit = MeasurementUnit.metric; // Assume recipes are generated in metric
    final displayUnit = state.measurementUnit;

    // Always perform conversion - even if servings are the same, unit conversion may be needed
    // This ensures the UI always reflects the current unit selection
    final converted = _conversionService.convertIngredients(
      ingredients: state.recipe.ingredients,
      originalServings: originalServings,
      newServings: displayServings,
      originalUnit: originalUnit,
      newUnit: displayUnit,
    );
    
    // Always update state with converted ingredients
    // Create a new list instance to ensure Riverpod detects the change
    final newConvertedIngredients = converted.map((ing) => RecipeIngredient(
      name: ing.name,
      amount: ing.amount,
      isUserProvided: ing.isUserProvided,
    )).toList();
    
    state = RecipeDisplayState(
      recipe: state.recipe,
      displayServings: displayServings,
      measurementUnit: displayUnit,
      convertedIngredients: newConvertedIngredients,
    );
  }
}
