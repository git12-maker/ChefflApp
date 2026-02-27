import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/smaakprofiel_service.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../../../shared/models/ingredient.dart';
import '../../../shared/models/smaakprofiel.dart';
import '../../../shared/models/balans_analyse.dart';
import 'dart:async';

/// State for smaakprofiel composition
class SmaakprofielState {
  const SmaakprofielState({
    this.ingredienten = const [],
    this.gecombineerdProfiel,
    this.balans,
    this.isLoading = false,
    this.error,
  });

  final List<IngredientSmaakprofiel> ingredienten;
  final Smaakprofiel? gecombineerdProfiel;
  final BalansAnalyse? balans;
  final bool isLoading;
  final String? error;

  SmaakprofielState copyWith({
    List<IngredientSmaakprofiel>? ingredienten,
    Smaakprofiel? gecombineerdProfiel,
    BalansAnalyse? balans,
    bool? isLoading,
    String? error,
  }) {
    return SmaakprofielState(
      ingredienten: ingredienten ?? this.ingredienten,
      gecombineerdProfiel: gecombineerdProfiel ?? this.gecombineerdProfiel,
      balans: balans ?? this.balans,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Provider for smaakprofiel state management
final smaakprofielProvider =
    StateNotifierProvider<SmaakprofielNotifier, SmaakprofielState>((ref) {
  return SmaakprofielNotifier();
});

/// Notifier for smaakprofiel state
class SmaakprofielNotifier extends StateNotifier<SmaakprofielState> {
  SmaakprofielNotifier() : super(const SmaakprofielState());

  final _smaakprofielService = SmaakprofielService.instance;
  final _culinaryService = CulinaryIntelligenceService.instance;
  
  Timer? _debounceTimer;

  /// Add ingredient to composition
  Future<void> voegIngredientToe(
    Ingredient ingredient, {
    String? cookingMethod,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Get smaakprofiel for ingredient
      final smaakprofiel = await _smaakprofielService.getSmaakprofiel(
        ingredient.id,
        cookingMethod: cookingMethod,
      );

      // Determine gewicht based on role
      final gewicht = ingredient.role == IngredientRole.carrier
          ? 100
          : ingredient.role == IngredientRole.supporting
              ? 25
              : ingredient.role == IngredientRole.accent
                  ? 15
                  : 10;

      final ingredientSmaakprofiel = IngredientSmaakprofiel(
        ingredient: ingredient,
        smaakprofiel: smaakprofiel,
        cookingMethod: cookingMethod,
        gewicht: gewicht,
      );

      // Add to list
      final nieuweIngredienten = [...state.ingredienten, ingredientSmaakprofiel];

      state = state.copyWith(
        ingredienten: nieuweIngredienten,
        isLoading: false,
      );

      // Recalculate profile (debounced)
      _berekenProfielDebounced();
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding ingredient: $e');
      debugPrint('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Fout bij toevoegen ingrediënt: ${e.toString()}',
      );
    }
  }

  /// Remove ingredient from composition
  Future<void> verwijderIngredient(String ingredientId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final nieuweIngredienten = state.ingredienten
          .where((i) => i.ingredient.id != ingredientId)
          .toList();

      state = state.copyWith(
        ingredienten: nieuweIngredienten,
        isLoading: false,
      );

      // Recalculate profile (debounced)
      _berekenProfielDebounced();
    } catch (e) {
      debugPrint('❌ Error removing ingredient: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fout bij verwijderen ingrediënt: ${e.toString()}',
      );
    }
  }

  /// Update cooking method for an ingredient
  Future<void> updateCookingMethod(
    String ingredientId,
    String? cookingMethod,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final nieuweIngredienten = <IngredientSmaakprofiel>[];

      for (final i in state.ingredienten) {
        if (i.ingredient.id == ingredientId) {
          // Get new smaakprofiel with updated cooking method
          final smaakprofiel = await _smaakprofielService.getSmaakprofiel(
            ingredientId,
            cookingMethod: cookingMethod,
          );
          nieuweIngredienten.add(IngredientSmaakprofiel(
            ingredient: i.ingredient,
            smaakprofiel: smaakprofiel,
            cookingMethod: cookingMethod,
            gewicht: i.gewicht,
          ));
        } else {
          nieuweIngredienten.add(i);
        }
      }

      state = state.copyWith(
        ingredienten: nieuweIngredienten,
        isLoading: false,
      );

      // Recalculate profile (debounced)
      _berekenProfielDebounced();
    } catch (e) {
      debugPrint('❌ Error updating cooking method: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fout bij updaten bereidingswijze: ${e.toString()}',
      );
    }
  }

  /// Calculate combined profile (debounced for performance)
  void _berekenProfielDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      berekenProfiel();
    });
  }

  /// Calculate combined smaakprofiel and balance analysis
  Future<void> berekenProfiel() async {
    if (state.ingredienten.isEmpty) {
      state = state.copyWith(
        gecombineerdProfiel: null,
        balans: null,
      );
      return;
    }

    try {
      // Calculate combined profile using weighted average
      final gecombineerdProfiel = _smaakprofielService.berekenGecombineerdProfiel(
        state.ingredienten,
      );

      // Analyze balance
      final balans = BalansAnalyzer.analyseer(gecombineerdProfiel);

      state = state.copyWith(
        gecombineerdProfiel: gecombineerdProfiel,
        balans: balans,
        error: null,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error calculating profile: $e');
      debugPrint('Stack trace: $stackTrace');
      state = state.copyWith(
        error: 'Fout bij berekenen smaakprofiel: ${e.toString()}',
      );
    }
  }

  /// Clear all ingredients
  void clearAll() {
    _debounceTimer?.cancel();
    state = const SmaakprofielState();
  }

  /// Get suggestions for missing elements
  Future<List<Ingredient>> getSuggesties() async {
    if (state.balans == null || state.balans!.ontbrekendeElementen.isEmpty) {
      return [];
    }

    try {
      final allIngredients = await _culinaryService.getAllIngredients();
      final currentIds = state.ingredienten
          .map((i) => i.ingredient.id)
          .toSet();

      final suggesties = <Ingredient>[];

      for (final ontbrekend in state.balans!.ontbrekendeElementen) {
        final candidates = _findCandidatesForMissing(
          allIngredients,
          ontbrekend,
          currentIds,
        );
        suggesties.addAll(candidates.take(3)); // Max 3 per missing element
      }

      // Remove duplicates
      final seen = <String>{};
      return suggesties.where((i) {
        if (seen.contains(i.id)) return false;
        seen.add(i.id);
        return true;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting suggestions: $e');
      return [];
    }
  }

  /// Find ingredient candidates for a missing element
  List<Ingredient> _findCandidatesForMissing(
    List<Ingredient> all,
    OntbrekendElement missing,
    Set<String> excludeIds,
  ) {
    switch (missing.type) {
      case OntbrekendElementType.strak:
        // Acidic ingredients, citrus, vinegar
        return all.where((i) {
          return !excludeIds.contains(i.id) &&
              (i.flavorProfile.sourness >= 0.5 ||
                  i.name.toLowerCase().contains('lemon') ||
                  i.name.toLowerCase().contains('lime') ||
                  i.name.toLowerCase().contains('vinegar') ||
                  i.name.toLowerCase().contains('citrus'));
        }).toList();

      case OntbrekendElementType.filmend:
        // Fatty, creamy, umami-rich ingredients
        return all.where((i) {
          return !excludeIds.contains(i.id) &&
              (i.moleculeType == MoleculeType.fat ||
                  i.mouthfeel == MouthfeelCategory.coating ||
                  i.flavorProfile.umami >= 0.5 ||
                  i.name.toLowerCase().contains('butter') ||
                  i.name.toLowerCase().contains('cream') ||
                  i.name.toLowerCase().contains('oil'));
        }).toList();

      case OntbrekendElementType.droog:
        // Crispy, crunchy, starchy ingredients
        return all.where((i) {
          return !excludeIds.contains(i.id) &&
              (i.textures.contains(TextureCategory.crispy) ||
                  i.textures.contains(TextureCategory.crunchy) ||
                  i.mouthfeel == MouthfeelCategory.dry ||
                  i.moleculeType == MoleculeType.carbohydrate);
        }).toList();

      case OntbrekendElementType.fris:
        // Fresh, green, citrus ingredients
        return all.where((i) {
          return !excludeIds.contains(i.id) &&
              (i.aromaCategories.contains('green') ||
                  i.aromaCategories.contains('fresh') ||
                  i.aromaCategories.contains('citrus') ||
                  i.role == IngredientRole.finishing);
        }).toList();

      case OntbrekendElementType.rijp:
        // Roasted, caramel, umami-rich ingredients
        return all.where((i) {
          return !excludeIds.contains(i.id) &&
              (i.aromaCategories.contains('roasted') ||
                  i.aromaCategories.contains('caramel') ||
                  i.aromaCategories.contains('earthy') ||
                  i.flavorProfile.umami >= 0.5);
        }).toList();

      case OntbrekendElementType.smaakgehalte:
        // High-intensity ingredients (spices, herbs, umami)
        return all.where((i) {
          return !excludeIds.contains(i.id) &&
              (i.aromaIntensity >= 0.7 ||
                  i.flavorProfile.umami >= 0.5 ||
                  i.role == IngredientRole.accent);
        }).toList();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
