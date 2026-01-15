import 'dart:convert';

/// Ingredient model with culinary properties for intelligent composition
/// Based on culinary science principles from Harold McGee, The Flavor Bible, and professional culinary standards

/// The role an ingredient plays in a dish composition
enum IngredientRole {
  /// The main element of the dish (protein, starch, or featured vegetable)
  carrier,

  /// Supporting ingredients that complement the carrier
  supporting,

  /// Small amounts that add specific flavor notes
  accent,

  /// Final touches that add freshness, color, or texture
  finishing,
}

/// The dominant macro-molecule in the ingredient
enum MoleculeType {
  water, // High water content (cucumbers, lettuce)
  fat, // High fat content (oils, butter, avocado)
  carbohydrate, // Starches and sugars (grains, root vegetables)
  protein, // High protein (meat, fish, legumes)
  mixed, // Balanced composition
}

/// Texture category for mouthfeel analysis
enum TextureCategory {
  crispy, // Fried, toasted, raw crunchy
  creamy, // Smooth, pureed, emulsified
  tender, // Properly cooked proteins, braised
  chewy, // Certain pastas, breads, meats
  silky, // Well-emulsified sauces, custards
  crunchy, // Raw vegetables, seeds, nuts
  soft, // Steamed, poached
  firm, // Al dente, raw
}

/// Mouthfeel sensation category
enum MouthfeelCategory {
  astringent, // Drying, puckering (tannins, unripe fruits)
  coating, // Smooth, lingering (fats, creamy sauces)
  dry, // Absorbing moisture (crackers, bread)
  refreshing, // Cooling, hydrating (cucumbers, melons)
  rich, // Full, satisfying (fatty foods)
}

/// Flavor profile with gustatory scores (0.0 to 1.0)
class FlavorProfile {
  const FlavorProfile({
    this.sweetness = 0.0,
    this.saltiness = 0.0,
    this.sourness = 0.0,
    this.bitterness = 0.0,
    this.umami = 0.0,
  });

  /// Sweetness level (0.0 - 1.0)
  final double sweetness;

  /// Saltiness level (0.0 - 1.0)
  final double saltiness;

  /// Sourness/acidity level (0.0 - 1.0)
  final double sourness;

  /// Bitterness level (0.0 - 1.0)
  final double bitterness;

  /// Umami/savory level (0.0 - 1.0)
  final double umami;

  /// Get the dominant taste
  String get dominantTaste {
    final scores = {
      'sweet': sweetness,
      'salty': saltiness,
      'sour': sourness,
      'bitter': bitterness,
      'umami': umami,
    };
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Check if flavor profile is balanced (no single taste overwhelming)
  bool get isBalanced {
    final values = [sweetness, saltiness, sourness, bitterness, umami];
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    return max - avg < 0.4; // No single taste more than 0.4 above average
  }

  factory FlavorProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FlavorProfile();
    return FlavorProfile(
      sweetness: (json['sweetness'] as num?)?.toDouble() ?? 0.0,
      saltiness: (json['saltiness'] as num?)?.toDouble() ?? 0.0,
      sourness: (json['sourness'] as num?)?.toDouble() ?? 0.0,
      bitterness: (json['bitterness'] as num?)?.toDouble() ?? 0.0,
      umami: (json['umami'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'sweetness': sweetness,
        'saltiness': saltiness,
        'sourness': sourness,
        'bitterness': bitterness,
        'umami': umami,
      };

  FlavorProfile operator +(FlavorProfile other) {
    return FlavorProfile(
      sweetness: sweetness + other.sweetness,
      saltiness: saltiness + other.saltiness,
      sourness: sourness + other.sourness,
      bitterness: bitterness + other.bitterness,
      umami: umami + other.umami,
    );
  }

  FlavorProfile operator /(num divisor) {
    return FlavorProfile(
      sweetness: sweetness / divisor,
      saltiness: saltiness / divisor,
      sourness: sourness / divisor,
      bitterness: bitterness / divisor,
      umami: umami / divisor,
    );
  }
}

/// Complete ingredient model with culinary intelligence properties
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    this.nameNl,
    this.description,
    this.categoryId,
    this.categoryName,
    this.flavorProfile = const FlavorProfile(),
    this.role = IngredientRole.supporting,
    this.moleculeType = MoleculeType.mixed,
    this.textures = const [],
    this.mouthfeel = MouthfeelCategory.refreshing,
    this.aromaIntensity = 0.5,
    this.aromaCategories = const [],
    this.season,
    this.pairingAffinities = const [],
    this.preparationMethods = const [],
    this.culinaryUses = const [],
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? nameNl;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final FlavorProfile flavorProfile;
  final IngredientRole role;
  final MoleculeType moleculeType;
  final List<TextureCategory> textures;
  final MouthfeelCategory mouthfeel;
  final double aromaIntensity; // 0.0 - 1.0
  final List<String> aromaCategories; // green, earthy, spicy, etc.
  final String? season;
  final List<String> pairingAffinities; // IDs of compatible ingredients
  final List<String> preparationMethods;
  final List<String> culinaryUses;
  final String? imageUrl;

  /// Check if this ingredient can serve as a carrier
  bool get canBeCarrier {
    return role == IngredientRole.carrier ||
        moleculeType == MoleculeType.protein ||
        moleculeType == MoleculeType.carbohydrate;
  }

  /// Check if this ingredient provides umami
  bool get providesUmami => flavorProfile.umami >= 0.5;

  /// Check if this ingredient provides acidity
  bool get providesAcidity => flavorProfile.sourness >= 0.5;

  /// Check if this ingredient provides crunch
  bool get providesCrunch =>
      textures.contains(TextureCategory.crispy) ||
      textures.contains(TextureCategory.crunchy);

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    // Parse flavor profile from JSONB
    FlavorProfile? flavorProfile;
    if (json['flavor_profile'] != null) {
      if (json['flavor_profile'] is String) {
        try {
          final parsed = json['flavor_profile'] as String;
          if (parsed.isNotEmpty) {
            // Handle string JSON
            final Map<String, dynamic> profileJson =
                Map<String, dynamic>.from(_parseJsonString(parsed));
            flavorProfile = FlavorProfile.fromJson(profileJson);
          }
        } catch (_) {
          flavorProfile = const FlavorProfile();
        }
      } else if (json['flavor_profile'] is Map) {
        flavorProfile =
            FlavorProfile.fromJson(json['flavor_profile'] as Map<String, dynamic>);
      }
    }

    // Parse textures
    List<TextureCategory> textures = [];
    if (json['texture'] != null && json['texture'].toString().isNotEmpty) {
      final textureStr = json['texture'].toString().toLowerCase();
      if (textureStr.contains('crispy') || textureStr.contains('knapperig')) {
        textures.add(TextureCategory.crispy);
      }
      if (textureStr.contains('creamy') || textureStr.contains('romig')) {
        textures.add(TextureCategory.creamy);
      }
      if (textureStr.contains('tender') || textureStr.contains('mals')) {
        textures.add(TextureCategory.tender);
      }
      if (textureStr.contains('chewy') || textureStr.contains('taai')) {
        textures.add(TextureCategory.chewy);
      }
      if (textureStr.contains('crunchy') || textureStr.contains('krokant')) {
        textures.add(TextureCategory.crunchy);
      }
      if (textureStr.contains('soft') || textureStr.contains('zacht')) {
        textures.add(TextureCategory.soft);
      }
      if (textureStr.contains('firm') || textureStr.contains('stevig')) {
        textures.add(TextureCategory.firm);
      }
    }

    // Determine role from database field or category
    IngredientRole role = IngredientRole.supporting;
    final culinaryRoleStr = json['culinary_role']?.toString().toLowerCase() ?? '';
    if (culinaryRoleStr == 'carrier') {
      role = IngredientRole.carrier;
    } else if (culinaryRoleStr == 'accent') {
      role = IngredientRole.accent;
    } else if (culinaryRoleStr == 'finishing') {
      role = IngredientRole.finishing;
    } else {
      // Fallback to category-based detection
      final categoryName = json['category_name']?.toString().toLowerCase() ?? '';
      if (categoryName.contains('protein') ||
          categoryName.contains('eiwit') ||
          categoryName.contains('vlees') ||
          categoryName.contains('vis') ||
          categoryName.contains('meat') ||
          categoryName.contains('fish')) {
        role = IngredientRole.carrier;
      } else if (categoryName.contains('grain') ||
          categoryName.contains('graan') ||
          categoryName.contains('pasta') ||
          categoryName.contains('rice') ||
          categoryName.contains('rijst')) {
        role = IngredientRole.carrier;
      } else if (categoryName.contains('herb') ||
          categoryName.contains('kruid') ||
          categoryName.contains('spice') ||
          categoryName.contains('specerij')) {
        role = IngredientRole.accent;
      }
    }
    
    // Parse molecule type from database
    MoleculeType moleculeType = MoleculeType.mixed;
    final moleculeTypeStr = json['molecule_type']?.toString().toLowerCase() ?? '';
    if (moleculeTypeStr == 'water') {
      moleculeType = MoleculeType.water;
    } else if (moleculeTypeStr == 'fat') {
      moleculeType = MoleculeType.fat;
    } else if (moleculeTypeStr == 'carbohydrate') {
      moleculeType = MoleculeType.carbohydrate;
    } else if (moleculeTypeStr == 'protein') {
      moleculeType = MoleculeType.protein;
    }
    
    // Parse mouthfeel from database
    MouthfeelCategory mouthfeel = MouthfeelCategory.refreshing;
    final mouthfeelStr = json['mouthfeel']?.toString().toLowerCase() ?? '';
    if (mouthfeelStr == 'astringent') {
      mouthfeel = MouthfeelCategory.astringent;
    } else if (mouthfeelStr == 'coating') {
      mouthfeel = MouthfeelCategory.coating;
    } else if (mouthfeelStr == 'dry') {
      mouthfeel = MouthfeelCategory.dry;
    } else if (mouthfeelStr == 'rich') {
      mouthfeel = MouthfeelCategory.rich;
    }
    
    // Parse aroma categories from database
    List<String> aromaCategories = [];
    if (json['aroma_categories'] != null) {
      if (json['aroma_categories'] is List) {
        aromaCategories = (json['aroma_categories'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return Ingredient(
      id: json['id']?.toString() ?? '',
      name: json['name_en']?.toString() ?? json['name_nl']?.toString() ?? '',
      nameNl: json['name_nl']?.toString(),
      description: json['description_en']?.toString() ?? json['description_nl']?.toString(),
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString(),
      flavorProfile: flavorProfile ?? const FlavorProfile(),
      role: role,
      moleculeType: moleculeType,
      textures: textures,
      mouthfeel: mouthfeel,
      aromaIntensity: double.tryParse(json['intensity']?.toString() ?? '0.5') ?? 0.5,
      aromaCategories: aromaCategories,
      season: json['season_en']?.toString() ?? json['season']?.toString(),
      preparationMethods: _parseStringList(json['preparation_methods_en'] ?? json['preparation_methods']),
      culinaryUses: _parseStringList(json['culinary_uses_en'] ?? json['culinary_uses']),
      imageUrl: json['hero_image_url']?.toString() ?? json['image_url']?.toString(),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  static Map<String, dynamic> _parseJsonString(String jsonStr) {
    // Parse JSON string (may have escaped quotes)
    try {
      // First try to parse as regular JSON
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      // If that fails, try manual parsing for escaped JSON strings
      try {
        // Remove outer braces and parse key-value pairs
        final content = jsonStr.trim();
        if (content.startsWith('{') && content.endsWith('}')) {
          final inner = content.substring(1, content.length - 1);
          final result = <String, dynamic>{};
          
          // Split by comma, but be careful with nested structures
          // Look for pattern: "key":value or "key":"value"
          final pattern = RegExp(r'"([^"]+)":\s*([^,}]+)');
          final matches = pattern.allMatches(inner);
          
          for (final match in matches) {
            final key = match.group(1) ?? '';
            var value = match.group(2)?.trim() ?? '';
            
            // Remove quotes if present
            if (value.startsWith('"') && value.endsWith('"')) {
              value = value.substring(1, value.length - 1);
            }
            
            // Try to parse as number
            final numValue = double.tryParse(value);
            if (numValue != null) {
              result[key] = numValue;
            } else {
              result[key] = value;
            }
          }
          
          return result;
        }
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_en': name,
        'name_nl': nameNl,
        'description_en': description,
        'category_id': categoryId,
        'flavor_profile': flavorProfile.toJson(),
        'role': role.name,
        'molecule_type': moleculeType.name,
        'textures': textures.map((t) => t.name).toList(),
        'mouthfeel': mouthfeel.name,
        'aroma_intensity': aromaIntensity,
        'aroma_categories': aromaCategories,
        'season': season,
        'pairing_affinities': pairingAffinities,
        'preparation_methods': preparationMethods,
        'culinary_uses': culinaryUses,
        'image_url': imageUrl,
      };
}
