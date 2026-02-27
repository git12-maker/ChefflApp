import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../shared/models/recipe.dart';

/// Simplified recipe service - saves to recipes, manages saves/favorites
class RecipeServiceSimple {
  RecipeServiceSimple._();
  static final RecipeServiceSimple instance = RecipeServiceSimple._();

  SupabaseClient get _client => SupabaseService.client;

  Future<Recipe> saveRecipe(Recipe recipe) async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) throw Exception('Must be logged in');

    final slug = _slugify(recipe.title);

    // Sanitize for DB constraints: difficulty lowercase, prep/cook > 0, servings 1-100
    final difficulty = recipe.difficulty?.toLowerCase();
    final validDifficulty = (difficulty == 'easy' || difficulty == 'medium' || difficulty == 'hard')
        ? difficulty
        : 'medium';
    final prep = recipe.prepTime;
    final cook = recipe.cookTime;
    final prepMinutes = (prep != null && prep > 0) ? prep : null;
    final cookMinutes = (cook != null && cook > 0) ? cook : null;
    final servings = recipe.servings != null
        ? (recipe.servings!).clamp(1, 100)
        : 2;

    final data = {
      'user_id': userId,
      'title': recipe.title,
      'slug': slug,
      'description': recipe.description ?? '',
      'ingredients': recipe.ingredients.map((e) => e.toJson()).toList(),
      'instructions': recipe.instructions,
      'primary_image_url': recipe.imageUrl,
      'prep_time_minutes': prepMinutes,
      'cook_time_minutes': cookMinutes,
      'servings': servings,
      'difficulty': validDifficulty,
      'cuisine_type': recipe.cuisine,
      'dietary_tags': recipe.dietaryTags,
      'deleted': false,
    };

    final response = await _client
        .from('recipes')
        .insert(data)
        .select()
        .single();

    final saved = _mapFromDb(response as Map<String, dynamic>);

    await _client.from('recipe_saves').insert({
      'user_id': userId,
      'recipe_id': saved.id,
    }).maybeSingle();

    return saved;
  }

  Future<List<Recipe>> getMyRecipes() async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) return [];

    final response = await _client
        .from('recipes')
        .select()
        .eq('user_id', userId)
        .eq('deleted', false)
        .order('created_at', ascending: false);

    final list = (response as List).map((e) => _mapFromDb(e as Map<String, dynamic>)).toList();
    final favIds = await _getFavoriteIds(userId);
    return list.map((r) => r.copyWith(isFavorite: r.id != null && favIds.contains(r.id))).toList();
  }

  Future<List<Recipe>> getSavedRecipes() async {
    return getMyRecipes();
  }

  Future<Set<String>> _getFavoriteIds(String userId) async {
    final r = await _client
        .from('recipe_favorites')
        .select('recipe_id')
        .eq('user_id', userId);
    return (r as List).map((e) => (e as Map)['recipe_id'] as String).toSet();
  }

  Future<void> toggleFavorite(String recipeId) async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) return;

    final existing = await _client
        .from('recipe_favorites')
        .select()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('recipe_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);
    } else {
      await _client.from('recipe_favorites').insert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
    }
  }

  Future<void> softDeleteRecipe(String recipeId) async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) return;
    await _client
        .from('recipes')
        .update({'deleted': true})
        .eq('id', recipeId)
        .eq('user_id', userId);
  }

  Future<Map<String, int>> getStats() async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) return {'total': 0, 'favorites': 0};
    final recipes = await getMyRecipes();
    final favCount = recipes.where((r) => r.isFavorite).length;
    final now = DateTime.now();
    final thisMonth = recipes.where((r) {
      final c = r.createdAt;
      return c != null && c.year == now.year && c.month == now.month;
    }).length;
    return {'total': recipes.length, 'favorites': favCount, 'thisMonth': thisMonth};
  }

  Future<bool> isFavorite(String recipeId) async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) return false;
    final r = await _client
        .from('recipe_favorites')
        .select()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId)
        .maybeSingle();
    return r != null;
  }

  String _slugify(String title) {
    final base = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return base.isEmpty ? 'recipe-$suffix' : '$base-$suffix';
  }

  Recipe _mapFromDb(Map<String, dynamic> json) {
    final ingredients = json['ingredients'];
    List<RecipeIngredient> ingList = [];
    if (ingredients is List) {
      ingList = ingredients
          .map((e) => RecipeIngredient.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    final instructions = json['instructions'];
    List<String> instrList = [];
    if (instructions is List) {
      instrList = instructions.map((e) => e.toString()).toList();
    }
    return Recipe(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      ingredients: ingList,
      instructions: instrList,
      prepTime: json['prep_time_minutes'] as int?,
      cookTime: json['cook_time_minutes'] as int?,
      servings: json['servings'] as int?,
      difficulty: json['difficulty'] as String?,
      cuisine: json['cuisine_type'] as String?,
      dietaryTags: (json['dietary_tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      imageUrl: json['primary_image_url'] as String? ?? json['image_url'] as String?,
      isFavorite: false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
