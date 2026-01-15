import 'package:collection/collection.dart';
import 'recipe_preferences.dart';

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.amount,
  });

  final String name;
  final String amount;

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
    );
  }
}

class Recipe {
  const Recipe({
    this.id,
    this.userId,
    required this.title,
    this.description,
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
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final String title;
  final String? description;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Recipe copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
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
          isFavorite == other.isFavorite;

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
      isFavorite.hashCode;
}
