import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Simple ingredient for selection - uses name or name_nl from DB
class SimpleIngredient {
  const SimpleIngredient({
    required this.id,
    required this.name,
    this.imageUrl,
    this.categoryName,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? categoryName;

  factory SimpleIngredient.fromJson(Map<String, dynamic> json) {
    return SimpleIngredient(
      id: json['id'] as String,
      name: (json['name'] ?? json['name_nl'] ?? json['display_name'] ?? '').toString(),
      imageUrl: json['image_url'] as String?,
      categoryName: json['categories']?['name'] as String?,
    );
  }
}

/// Fetches ingredients from Supabase - uses name/name_nl (no name_en)
class IngredientsService {
  IngredientsService._();
  static final IngredientsService instance = IngredientsService._();

  SupabaseClient get _client => SupabaseService.client;

  Future<List<SimpleIngredient>> getIngredients({
    String? search,
    String? categoryId,
  }) async {
    var query = _client
        .from('ingredients')
        .select('id, name, name_nl, display_name, image_url');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,name_nl.ilike.%$search%,display_name.ilike.%$search%');
    }

    final response = await query.order('name').limit(200);

    return (response as List)
        .map((e) => _mapIngredient(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all ingredient categories (id, name for display)
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client
        .from('ingredient_categories')
        .select('id, name_nl, name_en')
        .order('name_nl');
    return List<Map<String, dynamic>>.from(response as List);
  }

  SimpleIngredient _mapIngredient(Map<String, dynamic> json) {
    final name = json['name'] ?? json['name_nl'] ?? json['display_name'] ?? '';
    return SimpleIngredient(
      id: json['id'] as String,
      name: name.toString(),
      imageUrl: json['image_url'] as String?,
      categoryName: null,
    );
  }

  /// Returns a map of normalized ingredient name -> image URL for matching
  /// recipe ingredients to DB images. Uses lowercase for matching.
  Future<Map<String, String>> getIngredientNameToImageMap() async {
    final response = await _client
        .from('ingredients')
        .select('name, name_nl, image_url')
        .not('image_url', 'is', null);

    final map = <String, String>{};
    for (final row in response as List) {
      final r = row as Map<String, dynamic>;
      final url = r['image_url'] as String?;
      if (url == null || url.isEmpty) continue;
      for (final key in ['name', 'name_nl']) {
        final name = (r[key] ?? '').toString().trim();
        if (name.isNotEmpty) map[name.toLowerCase()] = url;
      }
    }
    return map;
  }
}
