/// Recipe preferences model used for AI generation
class RecipePreferences {
  const RecipePreferences({
    this.servings = 2,
    this.difficulty,
    this.cuisine,
    this.dietaryRestrictions = const [],
    this.maxTimeMinutes,
  });

  final int servings;
  final String? difficulty;
  final String? cuisine;
  final List<String> dietaryRestrictions;
  final int? maxTimeMinutes;

  RecipePreferences copyWith({
    int? servings,
    String? difficulty,
    String? cuisine,
    List<String>? dietaryRestrictions,
    int? maxTimeMinutes,
  }) {
    return RecipePreferences(
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      cuisine: cuisine ?? this.cuisine,
      dietaryRestrictions:
          dietaryRestrictions ?? List<String>.from(this.dietaryRestrictions),
      maxTimeMinutes: maxTimeMinutes ?? this.maxTimeMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'servings': servings,
      'difficulty': difficulty,
      'cuisine': cuisine,
      'dietary_restrictions': dietaryRestrictions,
      'max_time_minutes': maxTimeMinutes,
    };
  }
}
