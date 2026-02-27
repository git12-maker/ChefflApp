import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/ingredient.dart';
import '../shared/models/smaakprofiel.dart';
import 'cooking_methods_service.dart';

/// Smaakprofiel Service
/// 
/// Calculates combined flavor profiles using weighted averages
/// Based on universele smaakfactoren theory from boek_compleet.md
class SmaakprofielService {
  SmaakprofielService._();
  static final SmaakprofielService instance = SmaakprofielService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Get smaakprofiel for an ingredient (with optional cooking method)
  /// If cooking method is specified and no specific profile exists, applies deltas from cooking_effects
  Future<Smaakprofiel> getSmaakprofiel(
    String ingredientId, {
    String? cookingMethod,
  }) async {
    try {
      // First, get base profile (raw/default) - where cooking_method_id IS NULL
      // Fetch all profiles for this ingredient and filter for NULL cooking_method_id
      final allProfiles = await _supabase
          .from('flavor_profiles')
          .select()
          .eq('ingredient_id', ingredientId);
      
      final baseProfileData = (allProfiles as List).cast<Map<String, dynamic>>().firstWhere(
        (p) => p['cooking_method_id'] == null,
        orElse: () => <String, dynamic>{},
      );
      
      final baseResponse = baseProfileData.isEmpty ? null : baseProfileData;
      
      Smaakprofiel baseProfiel;
      if (baseResponse != null) {
        baseProfiel = Smaakprofiel.fromJson(baseResponse as Map<String, dynamic>);
      } else {
        // Fallback: calculate from ingredient data if no profile exists
        baseProfiel = await _calculateSmaakprofielFromIngredient(ingredientId);
      }

      // If no cooking method specified, return base profile
      if (cookingMethod == null || cookingMethod.isEmpty || cookingMethod == 'Raw') {
        return baseProfiel;
      }

      // Try to get specific profile for this cooking method
      final cookingMethods = await CookingMethodsService.instance.getAllCookingMethods();
      final method = cookingMethods.firstWhere(
        (m) => m.nameEn.toLowerCase() == cookingMethod.toLowerCase(),
        orElse: () => cookingMethods.first,
      );

      var methodQuery = _supabase
          .from('flavor_profiles')
          .select()
          .eq('ingredient_id', ingredientId)
          .eq('cooking_method_id', method.id);

      final methodResponse = await methodQuery.maybeSingle();

      if (methodResponse != null) {
        // Specific profile exists for this cooking method
        return Smaakprofiel.fromJson(methodResponse as Map<String, dynamic>);
      }

      // No specific profile - apply cooking method deltas to base profile
      return await _applyCookingMethodDeltas(baseProfiel, ingredientId, cookingMethod);
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting smaakprofiel for $ingredientId: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Smaakprofiel(); // Return default/neutral profile
    }
  }

  /// Apply cooking method deltas to a base smaakprofiel
  Future<Smaakprofiel> _applyCookingMethodDeltas(
    Smaakprofiel baseProfiel,
    String ingredientId,
    String cookingMethod,
  ) async {
    try {
      // Get cooking effect to find deltas
      final effect = await CookingMethodsService.instance.getCookingEffect(
        ingredientId,
        cookingMethod,
      );

      if (effect == null) {
        // No cooking effect data, return base
        return baseProfiel;
      }

      // Get deltas from cooking_effects table
      final cookingMethods = await CookingMethodsService.instance.getAllCookingMethods();
      final method = cookingMethods.firstWhere(
        (m) => m.nameEn.toLowerCase() == cookingMethod.toLowerCase(),
        orElse: () => cookingMethods.first,
      );

      final deltaResponse = await _supabase
          .from('ingredient_cooking_effects')
          .select('mondgevoel_strak_delta, mondgevoel_filmend_delta, mondgevoel_droog_delta, smaaktype_delta')
          .eq('ingredient_id', ingredientId)
          .eq('cooking_method_id', method.id)
          .maybeSingle();

      if (deltaResponse == null) {
        // No delta data, return base
        return baseProfiel;
      }

      // Apply deltas
      final strakDelta = (deltaResponse['mondgevoel_strak_delta'] as num?)?.toDouble() ?? 0.0;
      final filmendDelta = (deltaResponse['mondgevoel_filmend_delta'] as num?)?.toDouble() ?? 0.0;
      final droogDelta = (deltaResponse['mondgevoel_droog_delta'] as num?)?.toDouble() ?? 0.0;
      final smaaktypeDelta = (deltaResponse['smaaktype_delta'] as num?)?.toDouble() ?? 0.0;

      return Smaakprofiel(
        mondgevoel: Mondgevoel(
          strak: (baseProfiel.mondgevoel.strak + strakDelta).clamp(0.0, 1.0),
          filmend: (baseProfiel.mondgevoel.filmend + filmendDelta).clamp(0.0, 1.0),
          droog: (baseProfiel.mondgevoel.droog + droogDelta).clamp(0.0, 1.0),
        ),
        smaakrijkdom: Smaakrijkdom(
          gehalte: baseProfiel.smaakrijkdom.gehalte, // Gehalte doesn't change with cooking method
          type: (baseProfiel.smaakrijkdom.type + smaaktypeDelta).clamp(0.0, 1.0),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error applying cooking method deltas: $e');
      return baseProfiel; // Return base if delta application fails
    }
  }

  /// Calculate smaakprofiel from ingredient data (fallback method)
  /// This ensures ALL ingredients work, even if they don't have a flavor_profiles entry yet
  Future<Smaakprofiel> _calculateSmaakprofielFromIngredient(String ingredientId) async {
    try {
      final response = await _supabase
          .from('ingredients')
          .select('''
            id,
            name_en,
            name_nl,
            flavor_profile,
            mouthfeel,
            molecule_type,
            texture_en,
            texture_categories,
            aroma_intensity,
            aroma_categories,
            culinary_role
          ''')
          .eq('id', ingredientId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ Ingredient $ingredientId not found in database');
        return const Smaakprofiel(); // Return neutral profile
      }

      final ingredient = Ingredient.fromJson(response as Map<String, dynamic>);

      // Calculate mondgevoel from existing data
      final mondgevoel = Mondgevoel(
        strak: _calculateStrak(ingredient),
        filmend: _calculateFilmend(ingredient),
        droog: _calculateDroog(ingredient),
      );

      // Calculate smaakrijkdom from existing data
      // Use 0.3 as default if aromaIntensity is 0 or missing
      final smaakrijkdom = Smaakrijkdom(
        gehalte: ingredient.aromaIntensity > 0 ? ingredient.aromaIntensity : 0.3,
        type: _calculateSmaaktype(ingredient),
      );

      return Smaakprofiel(
        mondgevoel: mondgevoel,
        smaakrijkdom: smaakrijkdom,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error calculating smaakprofiel from ingredient: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Smaakprofiel(); // Return neutral profile as safe fallback
    }
  }

  /// Calculate strak component from ingredient
  double _calculateStrak(Ingredient ingredient) {
    if (ingredient.mouthfeel == MouthfeelCategory.astringent) return 0.8;
    if (ingredient.flavorProfile.sourness > 0.5) return 0.7;
    if (ingredient.flavorProfile.sourness > 0.3) return 0.5;
    if (ingredient.flavorProfile.saltiness > 0.5) return 0.3;
    return 0.1;
  }

  /// Calculate filmend component from ingredient
  double _calculateFilmend(Ingredient ingredient) {
    if (ingredient.mouthfeel == MouthfeelCategory.coating) return 0.8;
    if (ingredient.mouthfeel == MouthfeelCategory.rich) return 0.7;
    if (ingredient.moleculeType == MoleculeType.fat) return 0.9;
    if (ingredient.flavorProfile.umami > 0.5) return 0.6;
    if (ingredient.flavorProfile.umami > 0.3) return 0.4;
    return 0.1;
  }

  /// Calculate droog component from ingredient
  double _calculateDroog(Ingredient ingredient) {
    if (ingredient.mouthfeel == MouthfeelCategory.dry) return 0.8;
    if (ingredient.moleculeType == MoleculeType.carbohydrate) {
      if (ingredient.textures.contains(TextureCategory.crispy) ||
          ingredient.textures.contains(TextureCategory.crunchy)) {
        return 0.7;
      }
      return 0.4;
    }
    return 0.1;
  }

  /// Calculate smaaktype from ingredient
  double _calculateSmaaktype(Ingredient ingredient) {
    // Fris (0.0-0.3): green, fresh, citrus
    if (ingredient.aromaCategories.contains('green') ||
        ingredient.aromaCategories.contains('fresh') ||
        ingredient.aromaCategories.contains('citrus')) {
      return 0.2;
    }
    // Rijp (0.7-1.0): roasted, caramel, earthy
    if (ingredient.aromaCategories.contains('roasted') ||
        ingredient.aromaCategories.contains('caramel') ||
        ingredient.aromaCategories.contains('earthy')) {
      return 0.8;
    }
    if (ingredient.aromaCategories.contains('toasted') ||
        ingredient.aromaCategories.contains('smoky')) {
      return 0.75;
    }
    // Neutraal (0.4-0.6): default
    return 0.5;
  }

  /// Calculate combined smaakprofiel from multiple ingredients using weighted average
  /// Based on boek_compleet.md: gewogen gemiddelde berekening
  Smaakprofiel berekenGecombineerdProfiel(
    List<IngredientSmaakprofiel> ingredienten,
  ) {
    if (ingredienten.isEmpty) return const Smaakprofiel();

    final totaalGewicht = ingredienten.fold<int>(
      0,
      (sum, i) => sum + i.gewicht,
    );

    if (totaalGewicht == 0) return const Smaakprofiel();

    // Calculate weighted averages
    var combinedMondgevoel = const Mondgevoel();
    var combinedSmaakrijkdom = const Smaakrijkdom();

    for (final ingredient in ingredienten) {
      final factor = ingredient.gewicht / totaalGewicht;

      combinedMondgevoel = Mondgevoel(
        strak: combinedMondgevoel.strak + (ingredient.smaakprofiel.mondgevoel.strak * factor),
        filmend: combinedMondgevoel.filmend + (ingredient.smaakprofiel.mondgevoel.filmend * factor),
        droog: combinedMondgevoel.droog + (ingredient.smaakprofiel.mondgevoel.droog * factor),
      );

      combinedSmaakrijkdom = Smaakrijkdom(
        gehalte: combinedSmaakrijkdom.gehalte + (ingredient.smaakprofiel.smaakrijkdom.gehalte * factor),
        type: combinedSmaakrijkdom.type + (ingredient.smaakprofiel.smaakrijkdom.type * factor),
      );
    }

    // Normalize mondgevoel values to ensure they're within 0.0-1.0 range
    final mondgevoelSum = combinedMondgevoel.strak + combinedMondgevoel.filmend + combinedMondgevoel.droog;
    if (mondgevoelSum > 1.0) {
      combinedMondgevoel = Mondgevoel(
        strak: (combinedMondgevoel.strak / mondgevoelSum).clamp(0.0, 1.0),
        filmend: (combinedMondgevoel.filmend / mondgevoelSum).clamp(0.0, 1.0),
        droog: (combinedMondgevoel.droog / mondgevoelSum).clamp(0.0, 1.0),
      );
    }

    // Clamp smaakrijkdom values
    combinedSmaakrijkdom = Smaakrijkdom(
      gehalte: combinedSmaakrijkdom.gehalte.clamp(0.0, 1.0),
      type: combinedSmaakrijkdom.type.clamp(0.0, 1.0),
    );

    return Smaakprofiel(
      mondgevoel: combinedMondgevoel,
      smaakrijkdom: combinedSmaakrijkdom,
    );
  }

  /// Get smaakprofiel for multiple ingredients with their cooking methods
  Future<List<IngredientSmaakprofiel>> getIngredientSmaakprofielen(
    List<Ingredient> ingredients,
    Map<String, String>? cookingMethods,
  ) async {
    final result = <IngredientSmaakprofiel>[];

    for (final ingredient in ingredients) {
      final cookingMethod = cookingMethods?[ingredient.name];
      final smaakprofiel = await getSmaakprofiel(
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

      result.add(IngredientSmaakprofiel(
        ingredient: ingredient,
        smaakprofiel: smaakprofiel,
        cookingMethod: cookingMethod,
        gewicht: gewicht,
      ));
    }

    return result;
  }
}
