/// Model for recognized ingredient from image analysis
class RecognizedIngredient {
  const RecognizedIngredient({
    required this.name,
    required this.category,
    required this.confidence,
  });

  final String name;
  final String category; // vegetable, protein, dairy, grain, fruit, condiment, other
  final String confidence; // high, medium, low

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'confidence': confidence,
      };

  factory RecognizedIngredient.fromJson(Map<String, dynamic> json) {
    return RecognizedIngredient(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      confidence: json['confidence'] as String? ?? 'medium',
    );
  }

  RecognizedIngredient copyWith({
    String? name,
    String? category,
    String? confidence,
  }) {
    return RecognizedIngredient(
      name: name ?? this.name,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Get color for category
  static int getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetable':
        return 0xFF4CAF50; // Green
      case 'protein':
        return 0xFFE53935; // Red
      case 'dairy':
        return 0xFF2196F3; // Blue
      case 'grain':
        return 0xFFFFC107; // Yellow/Amber
      case 'fruit':
        return 0xFF9C27B0; // Purple
      case 'condiment':
        return 0xFFFF9800; // Orange
      default:
        return 0xFF757575; // Grey
    }
  }
}
