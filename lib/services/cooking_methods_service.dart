import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/ingredient.dart';

/// Service for managing cooking methods and their effects on ingredients
/// Based on scientific research from Harold McGee, Hervé This, and food chemistry studies
class CookingMethodsService {
  CookingMethodsService._();
  static final CookingMethodsService instance = CookingMethodsService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Get cooking effects for an ingredient with a specific cooking method
  Future<CookingEffect?> getCookingEffect(
    String ingredientId,
    String cookingMethodName,
  ) async {
    try {
      final response = await _supabase
          .from('ingredient_cooking_effects')
          .select('''
            *,
            cooking_methods (
              name_en,
              name_nl,
              heat_type,
              temperature_range_min,
              temperature_range_max
            )
          ''')
          .eq('ingredient_id', ingredientId)
          .eq('cooking_methods.name_en', cookingMethodName)
          .maybeSingle();

      if (response == null) return null;

      return CookingEffect.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching cooking effect: $e');
      return null;
    }
  }

  /// Get all cooking methods available for an ingredient
  Future<List<CookingMethod>> getCookingMethodsForIngredient(
    String ingredientId,
  ) async {
    try {
      final response = await _supabase
          .from('ingredient_cooking_effects')
          .select('''
            cooking_methods (
              id,
              name_en,
              name_nl,
              description_en,
              heat_type,
              temperature_range_min,
              temperature_range_max
            )
          ''')
          .eq('ingredient_id', ingredientId);

      if (response.isEmpty) return [];

      return (response as List)
          .map((e) => CookingMethod.fromJson(e['cooking_methods'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching cooking methods: $e');
      return [];
    }
  }

  /// Get all cooking methods from the database
  Future<List<CookingMethod>> getAllCookingMethods() async {
    try {
      final response = await _supabase
          .from('cooking_methods')
          .select('id, name_en, name_nl, description_en, heat_type, temperature_range_min, temperature_range_max')
          .order('name_en');

      if (response.isEmpty) return [];

      return (response as List)
          .map((e) => CookingMethod.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all cooking methods: $e');
      return [];
    }
  }

  /// Get optimal cooking method for an ingredient (based on confidence level and scientific source)
  Future<CookingMethod?> getOptimalCookingMethod(String ingredientId) async {
    try {
      final response = await _supabase
          .from('ingredient_cooking_effects')
          .select('''
            cooking_methods (
              id,
              name_en,
              name_nl,
              description_en,
              heat_type,
              temperature_range_min,
              temperature_range_max
            ),
            confidence_level,
            scientific_source
          ''')
          .eq('ingredient_id', ingredientId)
          .order('confidence_level', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final methodData = response['cooking_methods'] as Map<String, dynamic>?;
      if (methodData == null) return null;

      return CookingMethod.fromJson(methodData);
    } catch (e) {
      debugPrint('Error fetching optimal cooking method: $e');
      return null;
    }
  }

  /// Get cooking guidance text for LLM prompt
  /// Returns a formatted string explaining how to prepare the ingredient
  Future<String> getCookingGuidanceForIngredient(
    Ingredient ingredient,
    String? preferredMethod,
  ) async {
    final methodName = preferredMethod ?? 'Raw';
    
    // Try to get specific cooking effect
    final effect = await getCookingEffect(ingredient.id, methodName);
    
    if (effect != null) {
      return _formatCookingGuidance(ingredient, effect);
    }
    
    // Fallback: use general rules based on ingredient type and molecule type
    return _getGeneralCookingGuidance(ingredient, methodName);
  }

  String _formatCookingGuidance(Ingredient ingredient, CookingEffect effect) {
    final parts = <String>[];
    
    parts.add('${ingredient.name} (${effect.cookingMethod.nameEn}):');
    
    // Flavor changes
    if (effect.flavorDelta != null) {
      final flavorChanges = <String>[];
      if (effect.flavorDelta!.umami > 0.1) {
        flavorChanges.add('+${(effect.flavorDelta!.umami * 100).toStringAsFixed(0)}% umami');
      }
      if (effect.flavorDelta!.sweetness > 0.1) {
        flavorChanges.add('+${(effect.flavorDelta!.sweetness * 100).toStringAsFixed(0)}% sweetness');
      }
      if (flavorChanges.isNotEmpty) {
        parts.add('  Flavor: ${flavorChanges.join(", ")}');
      }
    }
    
    // Aroma changes
    if (effect.aromaCategoriesAdded.isNotEmpty) {
      parts.add('  Aroma: Adds ${effect.aromaCategoriesAdded.join(", ")}');
    }
    if (effect.aromaCategoriesRemoved.isNotEmpty) {
      parts.add('  Aroma: Removes ${effect.aromaCategoriesRemoved.join(", ")}');
    }
    
    // Texture changes
    if (effect.textureCategoriesAdded.isNotEmpty) {
      parts.add('  Texture: Becomes ${effect.textureCategoriesAdded.join(", ")}');
    }
    
    // Scientific reactions
    if (effect.maillardContribution > 0.5) {
      parts.add('  Maillard reaction: Strong browning and umami development');
    }
    if (effect.caramelizationContribution > 0.5) {
      parts.add('  Caramelization: Significant sweetness and golden color');
    }
    
    // Optimal conditions
    if (effect.optimalTemperature != null) {
      parts.add('  Optimal: ${effect.optimalTemperature}°C');
    }
    if (effect.optimalTimeMin != null) {
      parts.add('  Time: ${effect.optimalTimeMin} minutes');
    }
    
    return parts.join('\n');
  }

  String _getGeneralCookingGuidance(Ingredient ingredient, String methodName) {
    // General rules based on molecule type and ingredient characteristics
    final parts = <String>[];
    
    parts.add('${ingredient.name} (${methodName}):');
    
    // Molecule type based guidance
    switch (ingredient.moleculeType) {
      case MoleculeType.protein:
        if (methodName.toLowerCase().contains('roast') || 
            methodName.toLowerCase().contains('grill')) {
          parts.add('  Use high heat (180-220°C) for Maillard reaction and browning');
          parts.add('  Develops umami and savory flavors');
          parts.add('  Texture: Crispy exterior, tender interior');
        } else if (methodName.toLowerCase().contains('braise') || 
                   methodName.toLowerCase().contains('stew')) {
          parts.add('  Use low heat (80-100°C) for slow breakdown of collagen');
          parts.add('  Results in very tender, falling-apart texture');
        }
        break;
        
      case MoleculeType.carbohydrate:
        if (methodName.toLowerCase().contains('roast') || 
            methodName.toLowerCase().contains('fry')) {
          parts.add('  Develops caramelization and crispy texture');
          parts.add('  Sweetness increases with browning');
        } else if (methodName.toLowerCase().contains('boil') || 
                   methodName.toLowerCase().contains('steam')) {
          parts.add('  Gelatinizes starch, becomes tender');
          parts.add('  Preserves structure better with steaming');
        }
        break;
        
      case MoleculeType.fat:
        parts.add('  Melts and carries flavors');
        parts.add('  Creates richness and mouthfeel');
        break;
        
      case MoleculeType.water:
        if (methodName.toLowerCase().contains('roast') || 
            methodName.toLowerCase().contains('grill')) {
          parts.add('  Loses moisture, concentrates flavors');
          parts.add('  Can develop browning and caramelization');
        } else if (methodName.toLowerCase().contains('steam')) {
          parts.add('  Preserves freshness and structure');
          parts.add('  Minimal flavor loss');
        }
        break;
        
      default:
        break;
    }
    
    // Role-based guidance
    if (ingredient.role == IngredientRole.carrier) {
      parts.add('  Main element: Cook until properly done (check doneness)');
    } else if (ingredient.role == IngredientRole.finishing) {
      parts.add('  Finishing element: Add at the end to preserve freshness');
    }
    
    return parts.join('\n');
  }
}

/// Cooking method model
class CookingMethod {
  const CookingMethod({
    required this.id,
    required this.nameEn,
    this.nameNl,
    this.descriptionEn,
    this.heatType,
    this.temperatureRangeMin,
    this.temperatureRangeMax,
  });

  final String id;
  final String nameEn;
  final String? nameNl;
  final String? descriptionEn;
  final String? heatType;
  final int? temperatureRangeMin;
  final int? temperatureRangeMax;

  factory CookingMethod.fromJson(Map<String, dynamic> json) {
    return CookingMethod(
      id: json['id']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      nameNl: json['name_nl']?.toString(),
      descriptionEn: json['description_en']?.toString(),
      heatType: json['heat_type']?.toString(),
      temperatureRangeMin: json['temperature_range_min'] as int?,
      temperatureRangeMax: json['temperature_range_max'] as int?,
    );
  }
}

/// Cooking effect model - how a cooking method transforms an ingredient
class CookingEffect {
  const CookingEffect({
    required this.cookingMethod,
    this.flavorDelta,
    this.aromaIntensityChange = 0,
    this.aromaCategoriesAdded = const [],
    this.aromaCategoriesRemoved = const [],
    this.textureCategoriesAdded = const [],
    this.textureCategoriesRemoved = const [],
    this.mouthfeelChange,
    this.maillardContribution = 0,
    this.caramelizationContribution = 0,
    this.moistureLossPct,
    this.optimalTemperature,
    this.optimalTimeMin,
    this.scientificSource,
    this.confidenceLevel = 'medium',
  });

  final CookingMethod cookingMethod;
  final FlavorDelta? flavorDelta;
  final double aromaIntensityChange;
  final List<String> aromaCategoriesAdded;
  final List<String> aromaCategoriesRemoved;
  final List<String> textureCategoriesAdded;
  final List<String> textureCategoriesRemoved;
  final String? mouthfeelChange;
  final double maillardContribution;
  final double caramelizationContribution;
  final double? moistureLossPct;
  final int? optimalTemperature;
  final int? optimalTimeMin;
  final String? scientificSource;
  final String confidenceLevel;

  factory CookingEffect.fromJson(Map<String, dynamic> json) {
    FlavorDelta? flavorDelta;
    if (json['flavor_profile_delta'] != null) {
      final deltaJson = json['flavor_profile_delta'] as Map<String, dynamic>;
      flavorDelta = FlavorDelta(
        sweetness: (deltaJson['sweetness'] as num?)?.toDouble() ?? 0,
        saltiness: (deltaJson['saltiness'] as num?)?.toDouble() ?? 0,
        sourness: (deltaJson['sourness'] as num?)?.toDouble() ?? 0,
        bitterness: (deltaJson['bitterness'] as num?)?.toDouble() ?? 0,
        umami: (deltaJson['umami'] as num?)?.toDouble() ?? 0,
      );
    }

    final methodData = json['cooking_methods'] as Map<String, dynamic>?;
    final cookingMethod = methodData != null
        ? CookingMethod.fromJson(methodData)
        : CookingMethod(id: '', nameEn: 'Unknown');

    return CookingEffect(
      cookingMethod: cookingMethod,
      flavorDelta: flavorDelta,
      aromaIntensityChange:
          (json['aroma_intensity_change'] as num?)?.toDouble() ?? 0,
      aromaCategoriesAdded: (json['aroma_categories_added'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aromaCategoriesRemoved: (json['aroma_categories_removed'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      textureCategoriesAdded: (json['texture_categories_added'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      textureCategoriesRemoved: (json['texture_categories_removed'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mouthfeelChange: json['mouthfeel_change']?.toString(),
      maillardContribution:
          (json['maillard_contribution'] as num?)?.toDouble() ?? 0,
      caramelizationContribution:
          (json['caramelization_contribution'] as num?)?.toDouble() ?? 0,
      moistureLossPct: (json['moisture_loss_pct'] as num?)?.toDouble(),
      optimalTemperature: json['optimal_temperature'] as int?,
      optimalTimeMin: json['optimal_time_min'] as int?,
      scientificSource: json['scientific_source']?.toString(),
      confidenceLevel: json['confidence_level']?.toString() ?? 'medium',
    );
  }
}

/// Flavor profile delta - changes to flavor profile
class FlavorDelta {
  const FlavorDelta({
    this.sweetness = 0,
    this.saltiness = 0,
    this.sourness = 0,
    this.bitterness = 0,
    this.umami = 0,
  });

  final double sweetness;
  final double saltiness;
  final double sourness;
  final double bitterness;
  final double umami;
}
