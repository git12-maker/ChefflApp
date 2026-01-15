import 'package:collection/collection.dart';
import 'recipe_preferences.dart';

/// Visual description of the plated dish for image generation
class VisualDescription {
  const VisualDescription({
    this.overall,
    this.mainElement,
    this.components = const [],
    this.sauce,
    this.garnishes = const [],
    this.colorPalette = const [],
    this.platingStyle,
  });

  final String? overall;
  final VisualComponent? mainElement;
  final List<VisualComponent> components;
  final SaucePresentation? sauce;
  final List<String> garnishes;
  final List<String> colorPalette;
  final String? platingStyle;

  factory VisualDescription.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VisualDescription();
    return VisualDescription(
      overall: json['overall'] as String?,
      mainElement: json['main_element'] != null
          ? VisualComponent.fromJson(json['main_element'] as Map<String, dynamic>)
          : null,
      components: (json['components'] as List<dynamic>? ?? [])
          .map((e) => VisualComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      sauce: json['sauce'] != null
          ? SaucePresentation.fromJson(json['sauce'] as Map<String, dynamic>)
          : null,
      garnishes: (json['garnishes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      colorPalette: (json['color_palette'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      platingStyle: json['plating_style'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'main_element': mainElement?.toJson(),
        'components': components.map((e) => e.toJson()).toList(),
        'sauce': sauce?.toJson(),
        'garnishes': garnishes,
        'color_palette': colorPalette,
        'plating_style': platingStyle,
      };

  /// Generate a detailed description string for image prompts
  String toImagePromptDescription() {
    final parts = <String>[];
    
    if (overall != null && overall!.isNotEmpty) {
      parts.add(overall!);
    }
    
    if (mainElement != null) {
      parts.add('Main: ${mainElement!.toDescription()}');
    }
    
    for (final component in components) {
      parts.add(component.toDescription());
    }
    
    if (sauce != null && sauce!.type != null) {
      parts.add('Sauce: ${sauce!.toDescription()}');
    }
    
    if (garnishes.isNotEmpty) {
      parts.add('Garnished with ${garnishes.join(', ')}');
    }
    
    if (colorPalette.isNotEmpty) {
      parts.add('Colors: ${colorPalette.join(', ')}');
    }
    
    if (platingStyle != null) {
      parts.add('$platingStyle plating style');
    }
    
    return parts.join('. ');
  }
}

/// A visual component of the dish
class VisualComponent {
  const VisualComponent({
    required this.ingredient,
    this.appearance,
    this.portion,
    this.placement,
  });

  final String ingredient;
  final String? appearance;
  final String? portion;
  final String? placement;

  factory VisualComponent.fromJson(Map<String, dynamic> json) {
    return VisualComponent(
      ingredient: json['ingredient'] as String? ?? '',
      appearance: json['appearance'] as String?,
      portion: json['portion'] as String?,
      placement: json['placement'] as String? ?? json['position'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'ingredient': ingredient,
        'appearance': appearance,
        'portion': portion,
        'placement': placement,
      };

  String toDescription() {
    final parts = <String>[ingredient];
    if (appearance != null) parts.add(appearance!);
    if (portion != null) parts.add('($portion)');
    if (placement != null) parts.add('placed $placement');
    return parts.join(' - ');
  }
}

/// Sauce presentation details
class SaucePresentation {
  const SaucePresentation({
    this.type,
    this.appearance,
    this.presentation,
  });

  final String? type;
  final String? appearance;
  final String? presentation;

  factory SaucePresentation.fromJson(Map<String, dynamic> json) {
    return SaucePresentation(
      type: json['type'] as String?,
      appearance: json['appearance'] as String?,
      presentation: json['presentation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'appearance': appearance,
        'presentation': presentation,
      };

  String toDescription() {
    final parts = <String>[];
    if (type != null) parts.add(type!);
    if (appearance != null) parts.add(appearance!);
    if (presentation != null) parts.add('presented as $presentation');
    return parts.join(', ');
  }
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.amount,
    this.isUserProvided = false, // Track if ingredient was provided by user or auto-added from instructions
  });

  final String name;
  final String amount;
  final bool isUserProvided; // true = user provided, false = auto-added from instructions

  RecipeIngredient copyWith({
    String? name,
    String? amount,
    bool? isUserProvided,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isUserProvided: isUserProvided ?? this.isUserProvided,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'is_user_provided': isUserProvided,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      isUserProvided: json['is_user_provided'] as bool? ?? false,
    );
  }
}

class Recipe {
  const Recipe({
    this.id,
    this.userId,
    required this.title,
    this.description,
    this.visualDescription,
    required this.ingredients,
    required this.instructions,
    this.prepTime,
    this.cookTime,
    this.servings,
    this.difficulty,
    this.cuisine,
    this.dietaryTags = const [],
    this.imageUrl,
    this.isAiGenerated = true,
    this.isFavorite = false,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final String title;
  final String? description;
  final VisualDescription? visualDescription;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final String? difficulty;
  final String? cuisine;
  final List<String> dietaryTags;
  final String? imageUrl;
  final bool isAiGenerated;
  final bool isFavorite;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Recipe copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    VisualDescription? visualDescription,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? difficulty,
    String? cuisine,
    List<String>? dietaryTags,
    String? imageUrl,
    bool? isAiGenerated,
    bool? isFavorite,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      visualDescription: visualDescription ?? this.visualDescription,
      ingredients: ingredients ?? List<RecipeIngredient>.from(this.ingredients),
      instructions: instructions ?? List<String>.from(this.instructions),
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      cuisine: cuisine ?? this.cuisine,
      dietaryTags: dietaryTags ?? List<String>.from(this.dietaryTags),
      imageUrl: imageUrl ?? this.imageUrl,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isFavorite: isFavorite ?? this.isFavorite,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'visual_description': visualDescription?.toJson(),
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'instructions': instructions,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'cuisine': cuisine,
      'dietary_tags': dietaryTags,
      'image_url': imageUrl,
      'is_ai_generated': isAiGenerated,
      'is_favorite': isFavorite,
      'deleted': deleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      visualDescription: json['visual_description'] != null
          ? VisualDescription.fromJson(json['visual_description'] as Map<String, dynamic>)
          : null,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => RecipeIngredient.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      instructions: (json['instructions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      prepTime: json['prep_time'] as int?,
      cookTime: json['cook_time'] as int?,
      servings: json['servings'] as int?,
      difficulty: json['difficulty'] as String?,
      cuisine: json['cuisine'] as String?,
      dietaryTags: (json['dietary_tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      imageUrl: json['image_url'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ?? true,
      isFavorite: json['is_favorite'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          description == other.description &&
          const ListEquality().equals(ingredients, other.ingredients) &&
          const ListEquality().equals(instructions, other.instructions) &&
          prepTime == other.prepTime &&
          cookTime == other.cookTime &&
          servings == other.servings &&
          difficulty == other.difficulty &&
          cuisine == other.cuisine &&
          const ListEquality().equals(dietaryTags, other.dietaryTags) &&
          imageUrl == other.imageUrl &&
          isAiGenerated == other.isAiGenerated &&
          isFavorite == other.isFavorite &&
          deleted == other.deleted;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      description.hashCode ^
      ingredients.hashCode ^
      instructions.hashCode ^
      prepTime.hashCode ^
      cookTime.hashCode ^
      servings.hashCode ^
      difficulty.hashCode ^
      cuisine.hashCode ^
      dietaryTags.hashCode ^
      imageUrl.hashCode ^
      isAiGenerated.hashCode ^
      isFavorite.hashCode ^
      deleted.hashCode;
}
