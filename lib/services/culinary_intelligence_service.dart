import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/ingredient.dart';

/// Culinary Intelligence Service
/// 
/// Analyzes ingredient compositions and provides smart suggestions based on:
/// - Gustatory balance (sweet, salty, sour, bitter, umami)
/// - Texture variety
/// - Aromatic completeness
/// - Carrier presence
/// - Culinary pairing principles
/// 
/// Based on culinary science from Harold McGee, The Flavor Bible, and professional standards.
class CulinaryIntelligenceService {
  CulinaryIntelligenceService._();
  static final CulinaryIntelligenceService instance = CulinaryIntelligenceService._();

  SupabaseClient get _supabase => Supabase.instance.client;
  
  // Cache for ingredients
  List<Ingredient>? _ingredientsCache;
  Map<String, List<Ingredient>>? _categoryCache;

  /// Analyze the composition of selected ingredients
  Future<CompositionAnalysis> analyzeComposition(List<String> ingredientNames) async {
    final ingredients = await _getIngredientsByNames(ingredientNames);
    
    // Debug: Log matched ingredients
    debugPrint('🔍 Analyzing ${ingredientNames.length} ingredients: ${ingredientNames.join(", ")}');
    debugPrint('📦 Matched ${ingredients.length} ingredients from database');
    for (final ing in ingredients) {
      if (ing.id.isNotEmpty && !ing.id.startsWith('placeholder')) {
        debugPrint('  ✓ ${ing.name}: umami=${ing.flavorProfile.umami}, sour=${ing.flavorProfile.sourness}');
      } else {
        debugPrint('  ⚠ ${ing.name}: NOT FOUND IN DATABASE (placeholder)');
      }
    }
    
    // Filter out placeholders for analysis (they have no flavor data)
    final validIngredients = ingredients.where((i) => 
        i.id.isNotEmpty && !i.id.startsWith('placeholder')).toList();
    
    // Calculate combined flavor profile (only from valid ingredients)
    final combinedProfile = _calculateCombinedFlavorProfile(validIngredients);
    
    debugPrint('🎨 Combined flavor profile: sweet=${combinedProfile.sweetness.toStringAsFixed(2)}, salty=${combinedProfile.saltiness.toStringAsFixed(2)}, sour=${combinedProfile.sourness.toStringAsFixed(2)}, bitter=${combinedProfile.bitterness.toStringAsFixed(2)}, umami=${combinedProfile.umami.toStringAsFixed(2)}');
    
    // Identify the carrier
    final carrier = _identifyCarrier(validIngredients);
    
    // Analyze texture variety
    final textureAnalysis = _analyzeTextures(validIngredients);
    
    // Check for missing elements
    final missingElements = _identifyMissingElements(
      combinedProfile,
      textureAnalysis,
      carrier,
      validIngredients,
    );
    
    // Get smart suggestions
    final suggestions = await _generateSuggestions(
      validIngredients,
      missingElements,
      combinedProfile,
    );

    return CompositionAnalysis(
      ingredients: validIngredients,
      flavorProfile: combinedProfile,
      carrier: carrier,
      textureVariety: textureAnalysis,
      missingElements: missingElements,
      suggestions: suggestions,
      overallScore: _calculateOverallScore(combinedProfile, textureAnalysis, carrier, missingElements),
    );
  }

  /// Get all ingredients from database
  Future<List<Ingredient>> getAllIngredients() async {
    if (_ingredientsCache != null) return _ingredientsCache!;
    
    try {
      // First get all ingredients
      final ingredientsResponse = await _supabase
          .from('ingredients')
          .select('''
            id,
            name_nl,
            name_en,
            description_nl,
            description_en,
            flavor_profile,
            texture,
            texture_en,
            intensity,
            season,
            season_en,
            preparation_methods,
            preparation_methods_en,
            culinary_uses,
            culinary_uses_en,
            category_id,
            hero_image_url,
            image_url,
            culinary_role,
            molecule_type,
            mouthfeel,
            aroma_categories,
            pairing_affinities
          ''')
          .order('name_en');
      
      // Get all categories separately
      final categoriesResponse = await _supabase
          .from('ingredient_categories')
          .select('id, name_en, name_nl');
      
      // Create a map of category_id -> category name
      final categoryMap = <String, Map<String, String>>{};
      for (final cat in categoriesResponse as List) {
        final catId = cat['id']?.toString();
        if (catId != null) {
          categoryMap[catId] = {
            'name_en': cat['name_en']?.toString() ?? '',
            'name_nl': cat['name_nl']?.toString() ?? '',
          };
        }
      }
      
      _ingredientsCache = (ingredientsResponse as List).map((json) {
        // Add category name from map
        final Map<String, dynamic> ingredientJson = Map<String, dynamic>.from(json);
        final categoryId = json['category_id']?.toString();
        if (categoryId != null && categoryMap.containsKey(categoryId)) {
          ingredientJson['category_name'] = categoryMap[categoryId]!['name_en'] ?? 
              categoryMap[categoryId]!['name_nl'];
        }
        return Ingredient.fromJson(ingredientJson);
      }).toList();
      
      return _ingredientsCache!;
    } catch (e) {
      debugPrint('Error fetching ingredients: $e');
      return [];
    }
  }

  /// Get ingredients by category
  Future<Map<String, List<Ingredient>>> getIngredientsByCategory() async {
    if (_categoryCache != null) return _categoryCache!;
    
    final all = await getAllIngredients();
    _categoryCache = <String, List<Ingredient>>{};
    
    for (final ingredient in all) {
      final category = ingredient.categoryName ?? 'Other';
      _categoryCache![category] ??= [];
      _categoryCache![category]!.add(ingredient);
    }
    
    return _categoryCache!;
  }

  /// Search ingredients by name
  Future<List<Ingredient>> searchIngredients(String query) async {
    final all = await getAllIngredients();
    final queryLower = query.toLowerCase();
    
    return all.where((i) {
      return i.name.toLowerCase().contains(queryLower) ||
          (i.nameNl?.toLowerCase().contains(queryLower) ?? false);
    }).take(20).toList();
  }

  /// Get smart suggestions based on current selection
  Future<List<IngredientSuggestion>> getSuggestions(List<String> currentIngredients) async {
    final analysis = await analyzeComposition(currentIngredients);
    return analysis.suggestions;
  }

  /// Get ingredients by names (fuzzy matching)
  /// This matches user-typed ingredient names to database ingredients
  Future<List<Ingredient>> _getIngredientsByNames(List<String> names) async {
    final all = await getAllIngredients();
    final result = <Ingredient>[];
    
    for (final name in names) {
      final nameLower = name.toLowerCase().trim();
      Ingredient? match;
      
      // Strategy 1: Exact match (case-insensitive)
      match = all.firstWhere(
        (i) {
          final iName = i.name.toLowerCase();
          final iNameNl = i.nameNl?.toLowerCase() ?? '';
          return iName == nameLower || iNameNl == nameLower;
        },
        orElse: () => Ingredient(id: '', name: ''), // Placeholder
      );
      
      // Strategy 2: Word-based match (handles "chicken breast" matching "chicken")
      if (match == null || match.id.isEmpty) {
        final nameWords = nameLower.split(RegExp(r'[\s,-]+')).where((w) => w.length > 2).toList();
        for (final ingredient in all) {
          final iName = ingredient.name.toLowerCase();
          final iNameNl = ingredient.nameNl?.toLowerCase() ?? '';
          
          // Check if any word from user input matches ingredient name
          for (final word in nameWords) {
            if (iName.contains(word) || iNameNl.contains(word) ||
                iName.split(RegExp(r'[\s,-]+')).contains(word)) {
              match = ingredient;
              break;
            }
          }
          if (match != null && match.id.isNotEmpty) break;
        }
      }
      
      // Strategy 3: Partial substring match
      if (match == null || match.id.isEmpty) {
        match = all.firstWhere(
          (i) {
            final iName = i.name.toLowerCase();
            final iNameNl = i.nameNl?.toLowerCase() ?? '';
            return iName.contains(nameLower) || 
                   nameLower.contains(iName) ||
                   (iNameNl.isNotEmpty && (iNameNl.contains(nameLower) || nameLower.contains(iNameNl)));
          },
          orElse: () => Ingredient(id: '', name: ''), // Placeholder
        );
      }
      
      // If still no match, create a placeholder with default flavor profile
      if (match == null || match.id.isEmpty) {
        // Create a basic ingredient placeholder - we'll use default flavor profile
        match = Ingredient(
          id: 'placeholder-${name.hashCode}',
          name: name,
          flavorProfile: const FlavorProfile(), // Default - no flavor data
        );
        debugPrint('No match found for ingredient: $name');
      }
      
      result.add(match);
    }
    
    return result;
  }

  /// Calculate combined flavor profile of all ingredients
  FlavorProfile _calculateCombinedFlavorProfile(List<Ingredient> ingredients) {
    if (ingredients.isEmpty) return const FlavorProfile();
    
    var combined = const FlavorProfile();
    for (final ingredient in ingredients) {
      combined = combined + ingredient.flavorProfile;
    }
    
    // Average the scores
    return combined / ingredients.length;
  }

  /// Identify the carrier ingredient
  Ingredient? _identifyCarrier(List<Ingredient> ingredients) {
    // First look for explicit carriers
    for (final ingredient in ingredients) {
      if (ingredient.role == IngredientRole.carrier) {
        return ingredient;
      }
    }
    
    // Then look for proteins or starches
    for (final ingredient in ingredients) {
      if (ingredient.canBeCarrier) {
        return ingredient;
      }
    }
    
    return null;
  }

  /// Analyze texture variety
  TextureAnalysis _analyzeTextures(List<Ingredient> ingredients) {
    final allTextures = <TextureCategory>{};
    final mouthfeels = <MouthfeelCategory>{};
    
    for (final ingredient in ingredients) {
      allTextures.addAll(ingredient.textures);
      mouthfeels.add(ingredient.mouthfeel);
    }
    
    // Check for key texture contrasts
    final hasCrispy = allTextures.contains(TextureCategory.crispy) || 
                      allTextures.contains(TextureCategory.crunchy);
    final hasCreamy = allTextures.contains(TextureCategory.creamy) || 
                      allTextures.contains(TextureCategory.silky);
    final hasTender = allTextures.contains(TextureCategory.tender) || 
                      allTextures.contains(TextureCategory.soft);
    
    return TextureAnalysis(
      textures: allTextures.toList(),
      mouthfeels: mouthfeels.toList(),
      hasCrispyCreamy: hasCrispy && hasCreamy,
      hasVariety: allTextures.length >= 2,
      score: allTextures.length / 4.0, // Max 4 textures for perfect score
    );
  }

  /// Identify missing elements for a complete dish
  List<MissingElement> _identifyMissingElements(
    FlavorProfile profile,
    TextureAnalysis textures,
    Ingredient? carrier,
    List<Ingredient> ingredients,
  ) {
    final missing = <MissingElement>[];
    
    // Check for carrier
    if (carrier == null) {
      missing.add(MissingElement(
        type: ElementType.carrier,
        reason: 'A dish needs a main element (protein, starch, or featured vegetable)',
        priority: MissingPriority.high,
      ));
    }
    
    // Check for umami
    if (profile.umami < 0.3) {
      missing.add(MissingElement(
        type: ElementType.umami,
        reason: 'Umami creates depth and satisfaction in a dish',
        priority: MissingPriority.high,
      ));
    }
    
    // Check for acidity
    if (profile.sourness < 0.2) {
      missing.add(MissingElement(
        type: ElementType.acid,
        reason: 'Acid adds brightness and cuts through richness',
        priority: MissingPriority.medium,
      ));
    }
    
    // Check for texture variety
    if (!textures.hasVariety) {
      missing.add(MissingElement(
        type: ElementType.texture,
        reason: 'Contrasting textures make a dish more interesting',
        priority: MissingPriority.medium,
      ));
    }
    
    // Check for crispy element
    final hasCrispy = textures.textures.contains(TextureCategory.crispy) ||
                      textures.textures.contains(TextureCategory.crunchy);
    if (!hasCrispy && ingredients.length >= 3) {
      missing.add(MissingElement(
        type: ElementType.crunch,
        reason: 'A crispy element adds textural interest',
        priority: MissingPriority.low,
      ));
    }
    
    // Check for freshness (herbs, raw elements)
    final hasFreshness = ingredients.any((i) => 
        i.role == IngredientRole.finishing ||
        i.aromaCategories.contains('green') ||
        i.aromaCategories.contains('fresh'));
    if (!hasFreshness && ingredients.length >= 2) {
      missing.add(MissingElement(
        type: ElementType.freshness,
        reason: 'Fresh herbs or raw elements add vibrancy',
        priority: MissingPriority.low,
      ));
    }
    
    return missing;
  }

  /// Generate smart suggestions based on missing elements
  Future<List<IngredientSuggestion>> _generateSuggestions(
    List<Ingredient> currentIngredients,
    List<MissingElement> missingElements,
    FlavorProfile currentProfile,
  ) async {
    final suggestions = <IngredientSuggestion>[];
    final all = await getAllIngredients();
    final currentIds = currentIngredients.map((i) => i.id).toSet();
    
    for (final missing in missingElements) {
      final candidates = _findCandidatesForMissing(all, missing, currentIds);
      
      for (final candidate in candidates.take(3)) {
        suggestions.add(IngredientSuggestion(
          ingredient: candidate,
          reason: _getSuggestionReason(missing, candidate),
          missingElement: missing.type,
          priority: missing.priority,
        ));
      }
    }
    
    // Sort by priority
    suggestions.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    
    return suggestions.take(8).toList();
  }

  /// Find candidates to fill a missing element
  List<Ingredient> _findCandidatesForMissing(
    List<Ingredient> all,
    MissingElement missing,
    Set<String> excludeIds,
  ) {
    switch (missing.type) {
      case ElementType.carrier:
        return all.where((i) => 
            i.canBeCarrier && !excludeIds.contains(i.id)
        ).toList();
        
      case ElementType.umami:
        // Umami-rich ingredients based on culinary science
        final umamiIngredients = ['parmesan', 'soy sauce', 'miso', 'tomato', 
            'mushroom', 'anchovy', 'fish sauce', 'worcestershire', 'aged cheese',
            'seaweed', 'bonito', 'yeast extract'];
        return all.where((i) {
          final nameLower = i.name.toLowerCase();
          return !excludeIds.contains(i.id) && 
              (i.flavorProfile.umami >= 0.5 ||
               umamiIngredients.any((u) => nameLower.contains(u)));
        }).toList();
        
      case ElementType.acid:
        // Acidic ingredients
        final acidIngredients = ['lemon', 'lime', 'vinegar', 'tomato', 'wine',
            'yogurt', 'citrus', 'orange', 'tamarind', 'pickle'];
        return all.where((i) {
          final nameLower = i.name.toLowerCase();
          return !excludeIds.contains(i.id) && 
              (i.flavorProfile.sourness >= 0.5 ||
               acidIngredients.any((a) => nameLower.contains(a)));
        }).toList();
        
      case ElementType.texture:
      case ElementType.crunch:
        return all.where((i) => 
            !excludeIds.contains(i.id) && i.providesCrunch
        ).toList();
        
      case ElementType.freshness:
        // Fresh herbs and finishing ingredients
        final freshIngredients = ['parsley', 'cilantro', 'basil', 'mint', 'dill',
            'chive', 'green onion', 'scallion', 'microgreen', 'sprout'];
        return all.where((i) {
          final nameLower = i.name.toLowerCase();
          return !excludeIds.contains(i.id) && 
              (i.role == IngredientRole.finishing ||
               i.role == IngredientRole.accent ||
               freshIngredients.any((f) => nameLower.contains(f)));
        }).toList();
        
      case ElementType.richness:
        // Rich, fatty ingredients
        final richIngredients = ['butter', 'cream', 'oil', 'cheese', 'avocado',
            'coconut', 'nut', 'egg yolk'];
        return all.where((i) {
          final nameLower = i.name.toLowerCase();
          return !excludeIds.contains(i.id) && 
              (i.moleculeType == MoleculeType.fat ||
               richIngredients.any((r) => nameLower.contains(r)));
        }).toList();
    }
  }

  /// Get human-readable reason for a suggestion
  String _getSuggestionReason(MissingElement missing, Ingredient ingredient) {
    switch (missing.type) {
      case ElementType.carrier:
        return '${ingredient.name} can be the main element of your dish';
      case ElementType.umami:
        return '${ingredient.name} adds savory depth (umami)';
      case ElementType.acid:
        return '${ingredient.name} adds brightness and balance';
      case ElementType.texture:
        return '${ingredient.name} adds textural contrast';
      case ElementType.crunch:
        return '${ingredient.name} adds a satisfying crunch';
      case ElementType.freshness:
        return '${ingredient.name} adds fresh, vibrant notes';
      case ElementType.richness:
        return '${ingredient.name} adds richness and satisfaction';
    }
  }

  /// Calculate overall composition score (0-100)
  int _calculateOverallScore(
    FlavorProfile profile,
    TextureAnalysis textures,
    Ingredient? carrier,
    List<MissingElement> missing,
  ) {
    var score = 100;
    
    // Deduct for missing carrier
    if (carrier == null) score -= 25;
    
    // Deduct for low umami
    if (profile.umami < 0.3) score -= 15;
    
    // Deduct for missing acid
    if (profile.sourness < 0.2) score -= 10;
    
    // Deduct for poor texture variety
    if (!textures.hasVariety) score -= 10;
    
    // Deduct for each missing element
    for (final element in missing) {
      switch (element.priority) {
        case MissingPriority.high:
          score -= 10;
          break;
        case MissingPriority.medium:
          score -= 5;
          break;
        case MissingPriority.low:
          score -= 2;
          break;
      }
    }
    
    return score.clamp(0, 100);
  }

  /// Clear the cache (call when data might have changed)
  void clearCache() {
    _ingredientsCache = null;
    _categoryCache = null;
  }
}

/// Result of composition analysis
class CompositionAnalysis {
  const CompositionAnalysis({
    required this.ingredients,
    required this.flavorProfile,
    this.carrier,
    required this.textureVariety,
    required this.missingElements,
    required this.suggestions,
    required this.overallScore,
  });

  final List<Ingredient> ingredients;
  final FlavorProfile flavorProfile;
  final Ingredient? carrier;
  final TextureAnalysis textureVariety;
  final List<MissingElement> missingElements;
  final List<IngredientSuggestion> suggestions;
  final int overallScore; // 0-100
}

/// Analysis of texture composition
class TextureAnalysis {
  const TextureAnalysis({
    required this.textures,
    required this.mouthfeels,
    required this.hasCrispyCreamy,
    required this.hasVariety,
    required this.score,
  });

  final List<TextureCategory> textures;
  final List<MouthfeelCategory> mouthfeels;
  final bool hasCrispyCreamy;
  final bool hasVariety;
  final double score; // 0.0 - 1.0
}

/// Types of missing elements
enum ElementType {
  carrier,
  umami,
  acid,
  texture,
  crunch,
  freshness,
  richness,
}

/// Priority levels for missing elements
enum MissingPriority {
  high,
  medium,
  low,
}

/// A missing element in the composition
class MissingElement {
  const MissingElement({
    required this.type,
    required this.reason,
    required this.priority,
  });

  final ElementType type;
  final String reason;
  final MissingPriority priority;
}

/// A suggested ingredient with reason
class IngredientSuggestion {
  const IngredientSuggestion({
    required this.ingredient,
    required this.reason,
    required this.missingElement,
    required this.priority,
  });

  final Ingredient ingredient;
  final String reason;
  final ElementType missingElement;
  final MissingPriority priority;
}
