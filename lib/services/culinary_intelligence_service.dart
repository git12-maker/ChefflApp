import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/ingredient.dart';
import 'cooking_methods_service.dart';

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
  /// 
  /// [cookingMethods] is an optional map of ingredient name -> cooking method name
  /// If provided, ingredients will be transformed based on cooking method effects
  Future<CompositionAnalysis> analyzeComposition(
    List<String> ingredientNames, {
    Map<String, String>? cookingMethods,
  }) async {
    final ingredients = await _getIngredientsByNames(ingredientNames);
    
    // Apply cooking methods if provided
    final transformedIngredients = await _applyCookingMethods(
      ingredients,
      cookingMethods,
    );
    
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
    final validIngredients = transformedIngredients.where((i) => 
        i.id.isNotEmpty && !i.id.startsWith('placeholder')).toList();
    
    // Calculate combined flavor profile (using transformed ingredients)
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

    // Analyze visual presentation if we have ingredient data
    final visualAnalysis = _analyzeVisualPresentation(validIngredients);
    
    return CompositionAnalysis(
      ingredients: validIngredients,
      flavorProfile: combinedProfile,
      carrier: carrier,
      textureVariety: textureAnalysis,
      missingElements: missingElements,
      suggestions: suggestions,
      overallScore: _calculateOverallScore(combinedProfile, textureAnalysis, carrier, missingElements),
      visualPresentation: visualAnalysis,
    );
  }

  /// Apply cooking method transformations to a list of ingredients
  Future<List<Ingredient>> _applyCookingMethods(
    List<Ingredient> ingredients,
    Map<String, String>? cookingMethods,
  ) async {
    if (cookingMethods == null || cookingMethods.isEmpty) {
      return ingredients; // No transformations
    }
    
    final transformed = <Ingredient>[];
    
    for (final ingredient in ingredients) {
      final methodName = cookingMethods[ingredient.name];
      if (methodName != null && methodName.isNotEmpty && methodName != 'Raw') {
        final transformedIngredient = await _applyCookingMethod(
          ingredient,
          methodName,
        );
        transformed.add(transformedIngredient);
      } else {
        transformed.add(ingredient); // No method specified or Raw
      }
    }
    
    return transformed;
  }

  /// Apply a single cooking method transformation to an ingredient
  Future<Ingredient> _applyCookingMethod(
    Ingredient ingredient,
    String methodName,
  ) async {
    try {
      // Fetch cooking effect
      final effect = await CookingMethodsService.instance.getCookingEffect(
        ingredient.id,
        methodName,
      );
      
      if (effect == null) {
        // No specific data, return original
        debugPrint('⚠️ No cooking effect data for ${ingredient.name} with $methodName');
        return ingredient;
      }
      
      // Apply flavor profile delta
      final baseProfile = ingredient.flavorProfile;
      final delta = effect.flavorDelta;
      final transformedProfile = FlavorProfile(
        sweetness: (baseProfile.sweetness + (delta?.sweetness ?? 0.0)).clamp(0.0, 1.0),
        saltiness: (baseProfile.saltiness + (delta?.saltiness ?? 0.0)).clamp(0.0, 1.0),
        sourness: (baseProfile.sourness + (delta?.sourness ?? 0.0)).clamp(0.0, 1.0),
        bitterness: (baseProfile.bitterness + (delta?.bitterness ?? 0.0)).clamp(0.0, 1.0),
        umami: (baseProfile.umami + (delta?.umami ?? 0.0)).clamp(0.0, 1.0),
      );
      
      // Apply aroma changes
      final transformedAromaCategories = [
        ...ingredient.aromaCategories.where(
          (cat) => !effect.aromaCategoriesRemoved.contains(cat)
        ),
        ...effect.aromaCategoriesAdded,
      ];
      final transformedAromaIntensity = (ingredient.aromaIntensity + 
          (effect.aromaIntensityChange ?? 0.0)).clamp(0.0, 1.0);
      
      // Apply texture changes
      // Convert texture category strings to TextureCategory enums
      final removedTextures = effect.textureCategoriesRemoved.map((str) {
        try {
          return TextureCategory.values.firstWhere(
            (e) => e.name.toLowerCase() == str.toLowerCase(),
            orElse: () => TextureCategory.soft,
          );
        } catch (_) {
          return TextureCategory.soft;
        }
      }).toList();
      
      final addedTextures = effect.textureCategoriesAdded.map((str) {
        try {
          return TextureCategory.values.firstWhere(
            (e) => e.name.toLowerCase() == str.toLowerCase(),
            orElse: () => TextureCategory.soft,
          );
        } catch (_) {
          return TextureCategory.soft;
        }
      }).toList();
      
      final transformedTextures = [
        ...ingredient.textures.where(
          (tex) => !removedTextures.contains(tex)
        ),
        ...addedTextures,
      ];
      
      // Apply mouthfeel change if specified
      final transformedMouthfeel = effect.mouthfeelChange != null
          ? _parseMouthfeel(effect.mouthfeelChange!)
          : ingredient.mouthfeel;
      
      // Create transformed ingredient
      return Ingredient(
        id: ingredient.id,
        name: ingredient.name,
        nameNl: ingredient.nameNl,
        description: ingredient.description,
        categoryId: ingredient.categoryId,
        categoryName: ingredient.categoryName,
        flavorProfile: transformedProfile,
        role: ingredient.role,
        moleculeType: ingredient.moleculeType,
        textures: transformedTextures,
        mouthfeel: transformedMouthfeel,
        aromaCategories: transformedAromaCategories,
        aromaIntensity: transformedAromaIntensity,
        pairingAffinities: ingredient.pairingAffinities,
        preparationMethods: ingredient.preparationMethods,
        imageUrl: ingredient.imageUrl,
        season: ingredient.season,
        culinaryUses: ingredient.culinaryUses,
      );
    } catch (e) {
      debugPrint('❌ Error applying cooking method $methodName to ${ingredient.name}: $e');
      return ingredient; // Fallback to original
    }
  }

  /// Parse mouthfeel string to MouthfeelCategory enum
  MouthfeelCategory _parseMouthfeel(String value) {
    switch (value.toLowerCase()) {
      case 'astringent':
        return MouthfeelCategory.astringent;
      case 'coating':
        return MouthfeelCategory.coating;
      case 'dry':
        return MouthfeelCategory.dry;
      case 'refreshing':
        return MouthfeelCategory.refreshing;
      case 'rich':
        return MouthfeelCategory.rich;
      default:
        return MouthfeelCategory.refreshing;
    }
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
            texture_categories,
            intensity,
            aroma_intensity,
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
      Ingredient match = Ingredient(id: '', name: '');
      
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
      if (match.id.isEmpty) {
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
          if (match.id.isNotEmpty) break;
        }
      }
      
      // Strategy 3: Partial substring match
      if (match.id.isEmpty) {
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
      
      if (match.id.isNotEmpty) {
        result.add(match);
      } else {
        debugPrint('No database match found for user ingredient: $name');
      }
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

  /// Analyze texture variety using structured texture_categories and mouthfeel
  TextureAnalysis _analyzeTextures(List<Ingredient> ingredients) {
    final allTextures = <TextureCategory>{};
    final mouthfeels = <MouthfeelCategory>{};
    
    for (final ingredient in ingredients) {
      // Use structured texture_categories (preferred) or fallback to parsed textures
      if (ingredient.textures.isNotEmpty) {
        allTextures.addAll(ingredient.textures);
      }
      // Use mouthfeel from database
      mouthfeels.add(ingredient.mouthfeel);
    }
    
    // Check for key texture contrasts (scientific principle: contrast creates interest)
    final hasCrispy = allTextures.contains(TextureCategory.crispy) || 
                      allTextures.contains(TextureCategory.crunchy);
    final hasCreamy = allTextures.contains(TextureCategory.creamy) || 
                      allTextures.contains(TextureCategory.silky);
    
    // Check for mouthfeel variety (coating vs refreshing, rich vs astringent)
    final hasMouthfeelVariety = mouthfeels.length >= 2;
    
    return TextureAnalysis(
      textures: allTextures.toList(),
      mouthfeels: mouthfeels.toList(),
      hasCrispyCreamy: hasCrispy && hasCreamy,
      hasVariety: allTextures.length >= 2 || hasMouthfeelVariety,
      score: (allTextures.length / 4.0).clamp(0.0, 1.0), // Max 4 textures for perfect score
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
    final cookingService = CookingMethodsService.instance;
    
    for (final missing in missingElements) {
      final candidates = _findCandidatesForMissing(all, missing, currentIds);
      
      // Include all candidates for each missing element (no limit)
      for (final candidate in candidates) {
        // Get optimal cooking method for this ingredient
        final optimalMethod = await cookingService.getOptimalCookingMethod(candidate.id);
        
        suggestions.add(IngredientSuggestion(
          ingredient: candidate,
          reason: _getSuggestionReason(missing, candidate),
          missingElement: missing.type,
          priority: missing.priority,
          optimalCookingMethod: optimalMethod?.nameEn,
        ));
      }
    }
    
    // Remove duplicates (same ingredient for different missing elements)
    final seen = <String>{};
    final uniqueSuggestions = <IngredientSuggestion>[];
    for (final suggestion in suggestions) {
      if (!seen.contains(suggestion.ingredient.id)) {
        seen.add(suggestion.ingredient.id);
        uniqueSuggestions.add(suggestion);
      }
    }
    
    // Sort by priority (high first), then by ingredient name for consistency
    uniqueSuggestions.sort((a, b) {
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return a.ingredient.name.compareTo(b.ingredient.name);
    });
    
    // Return all unique suggestions (no limit)
    return uniqueSuggestions;
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
        // Fresh herbs and finishing ingredients (use aroma_categories for better detection)
        final freshIngredients = ['parsley', 'cilantro', 'basil', 'mint', 'dill',
            'chive', 'green onion', 'scallion', 'microgreen', 'sprout'];
        return all.where((i) {
          final nameLower = i.name.toLowerCase();
          return !excludeIds.contains(i.id) && 
              (i.role == IngredientRole.finishing ||
               i.role == IngredientRole.accent ||
               i.aromaCategories.contains('green') ||
               i.aromaCategories.contains('fresh') ||
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
        
      case ElementType.aroma:
        // Ingredients with specific aroma categories
        // Try to find ingredients that fill the missing aroma type
        return all.where((i) {
          if (excludeIds.contains(i.id)) return false;
          // Prefer ingredients with strong aromas
          return i.aromaIntensity >= 0.5 && i.aromaCategories.isNotEmpty;
        }).toList();
        
      case ElementType.mouthfeel:
        // Ingredients with different mouthfeel than current selection
        final currentMouthfeels = <MouthfeelCategory>{};
        // This would need to be passed in, but for now use a general approach
        return all.where((i) {
          if (excludeIds.contains(i.id)) return false;
          // Prefer ingredients with distinct mouthfeel
          return i.mouthfeel != MouthfeelCategory.refreshing || 
                 i.moleculeType == MoleculeType.fat ||
                 i.moleculeType == MoleculeType.protein;
        }).toList();
        
      case ElementType.cookingMethod:
        // For cooking method suggestions, return all ingredients
        // The actual suggestion logic is handled elsewhere
        return all.where((i) => !excludeIds.contains(i.id)).toList();
    }
  }

  /// Get human-readable reason for a suggestion
  String _getSuggestionReason(MissingElement missing, Ingredient ingredient) {
    // Add molecule type context for better explanations
    String moleculeContext = '';
    switch (ingredient.moleculeType) {
      case MoleculeType.water:
        moleculeContext = ' (adds moisture and freshness)';
        break;
      case MoleculeType.fat:
        moleculeContext = ' (adds richness and carries flavors)';
        break;
      case MoleculeType.carbohydrate:
        moleculeContext = ' (adds energy and structure)';
        break;
      case MoleculeType.protein:
        moleculeContext = ' (adds satisfaction and umami)';
        break;
      default:
        break;
    }
    
    switch (missing.type) {
      case ElementType.carrier:
        return '${ingredient.name} can be the main element of your dish$moleculeContext';
      case ElementType.umami:
        return '${ingredient.name} adds savory depth (umami)$moleculeContext';
      case ElementType.acid:
        return '${ingredient.name} adds brightness and balance$moleculeContext';
      case ElementType.texture:
        return '${ingredient.name} adds textural contrast$moleculeContext';
      case ElementType.crunch:
        return '${ingredient.name} adds a satisfying crunch$moleculeContext';
      case ElementType.freshness:
        return '${ingredient.name} adds fresh, vibrant notes$moleculeContext';
      case ElementType.richness:
        return '${ingredient.name} adds richness and satisfaction$moleculeContext';
      case ElementType.aroma:
        return '${ingredient.name} adds aromatic complexity$moleculeContext';
      case ElementType.mouthfeel:
        return '${ingredient.name} adds mouthfeel variety$moleculeContext';
      case ElementType.cookingMethod:
        return 'Consider optimal cooking method for ${ingredient.name}$moleculeContext';
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

  /// Analyze visual presentation based on ingredients
  VisualPresentationAnalysis _analyzeVisualPresentation(List<Ingredient> ingredients) {
    // Collect color palette from ingredients
    final colorPalette = <String>{};
    for (final ingredient in ingredients) {
      // Infer colors from ingredient names and categories
      final nameLower = ingredient.name.toLowerCase();
      if (nameLower.contains('tomato') || nameLower.contains('red pepper')) {
        colorPalette.add('red');
      }
      if (nameLower.contains('carrot') || nameLower.contains('orange')) {
        colorPalette.add('orange');
      }
      if (nameLower.contains('lettuce') || nameLower.contains('green') || 
          nameLower.contains('basil') || nameLower.contains('parsley')) {
        colorPalette.add('green');
      }
      if (nameLower.contains('egg') || nameLower.contains('cheese') || 
          nameLower.contains('potato')) {
        colorPalette.add('yellow/cream');
      }
      if (nameLower.contains('beet') || nameLower.contains('purple')) {
        colorPalette.add('purple');
      }
      if (nameLower.contains('mushroom') || nameLower.contains('meat') || 
          nameLower.contains('beef')) {
        colorPalette.add('brown');
      }
    }
    
    // Check plating principles
    final hasColorContrast = colorPalette.length >= 3;
    final hasOddNumberElements = ingredients.length % 2 == 1 || ingredients.length >= 3;
    
    // Check for garnish potential (herbs, finishing ingredients)
    final hasGarnishPotential = ingredients.any((i) => 
        i.role == IngredientRole.finishing ||
        i.aromaCategories.contains('green') ||
        i.name.toLowerCase().contains('herb'));
    
    return VisualPresentationAnalysis(
      colorPalette: colorPalette.toList(),
      hasColorContrast: hasColorContrast,
      hasOddNumberElements: hasOddNumberElements,
      hasGarnishPotential: hasGarnishPotential,
      suggestions: _getVisualPresentationSuggestions(ingredients, colorPalette),
    );
  }
  
  List<String> _getVisualPresentationSuggestions(
    List<Ingredient> ingredients,
    Set<String> colorPalette,
  ) {
    final suggestions = <String>[];
    
    if (colorPalette.length < 3) {
      suggestions.add('Add ingredients with contrasting colors (red, green, yellow) for visual appeal');
    }
    
    if (ingredients.length % 2 == 0 && ingredients.length < 4) {
      suggestions.add('Consider adding one more element for odd-number plating (3, 5, or 7 elements)');
    }
    
    final hasGarnish = ingredients.any((i) => 
        i.role == IngredientRole.finishing ||
        i.aromaCategories.contains('green'));
    if (!hasGarnish) {
      suggestions.add('Add fresh herbs or finishing touches for color and aroma');
    }
    
    return suggestions;
  }

  /// Clear the cache (call when data might have changed)
  void clearCache() {
    _ingredientsCache = null;
    _categoryCache = null;
  }
}

/// Analysis of visual presentation
class VisualPresentationAnalysis {
  const VisualPresentationAnalysis({
    required this.colorPalette,
    required this.hasColorContrast,
    required this.hasOddNumberElements,
    required this.hasGarnishPotential,
    required this.suggestions,
  });

  final List<String> colorPalette;
  final bool hasColorContrast;
  final bool hasOddNumberElements;
  final bool hasGarnishPotential;
  final List<String> suggestions;
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
    this.visualPresentation,
  });

  final List<Ingredient> ingredients;
  final FlavorProfile flavorProfile;
  final Ingredient? carrier;
  final TextureAnalysis textureVariety;
  final List<MissingElement> missingElements;
  final List<IngredientSuggestion> suggestions;
  final int overallScore; // 0-100
  final VisualPresentationAnalysis? visualPresentation;
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
  aroma,
  mouthfeel,
  cookingMethod,
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
    this.optimalCookingMethod,
  });

  final Ingredient ingredient;
  final String reason;
  final ElementType missingElement;
  final MissingPriority priority;
  final String? optimalCookingMethod;
}
