import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/recipe.dart';
import 'supabase_service.dart';
import 'image_storage_service.dart';

/// Recipe service for Supabase CRUD operations
class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Generate a URL-friendly slug from title
  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
        .trim()
        .replaceAll(RegExp(r'^-+|-+$'), ''); // Remove leading/trailing hyphens
  }

  /// Save a recipe for the current user
  /// Automatically uploads image to Supabase Storage if it's not already stored there
  Future<Recipe> saveRecipe(Recipe recipe) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Generate unique slug (add timestamp to ensure uniqueness)
    final baseSlug = _generateSlug(recipe.title);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final slug = '$baseSlug-$timestamp';

    // Ensure image is stored in Supabase Storage before saving recipe
    String? finalImageUrl = recipe.imageUrl;
    if (finalImageUrl != null) {
      final imageStorage = ImageStorageService.instance;
      
      // If image is not already in Supabase Storage, upload it
      if (!imageStorage.isSupabaseStorageUrl(finalImageUrl)) {
        // Use temporary ID for storage path (will be updated after recipe is saved)
        final tempRecipeId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
        final storedUrl = await imageStorage.uploadImageFromUrl(
          imageUrl: finalImageUrl,
          recipeId: tempRecipeId,
        );
        
        // Use stored URL if upload succeeded
        if (storedUrl != null) {
          finalImageUrl = storedUrl;
        }
      }
    }

    // Map Recipe model to database schema
    // Note: prep_time_minutes and cook_time_minutes must be > 0 if not null
    final recipeData = <String, dynamic>{
      'title': recipe.title,
      'slug': slug,
      'description': recipe.description,
      'ingredients': recipe.ingredients.map((e) => e.toJson()).toList(),
      'instructions': recipe.instructions,
      'prep_time_minutes': (recipe.prepTime != null && recipe.prepTime! > 0) 
          ? recipe.prepTime 
          : null,
      'cook_time_minutes': (recipe.cookTime != null && recipe.cookTime! > 0) 
          ? recipe.cookTime 
          : null,
      'servings': (recipe.servings != null && recipe.servings! >= 1 && recipe.servings! <= 100)
          ? recipe.servings
          : 4,
      'difficulty': recipe.difficulty != null && 
          ['easy', 'medium', 'hard'].contains(recipe.difficulty!.toLowerCase())
          ? recipe.difficulty!.toLowerCase()
          : null,
      'cuisine_type': recipe.cuisine,
      'dietary_tags': recipe.dietaryTags.isNotEmpty ? recipe.dietaryTags : null,
      'primary_image_url': finalImageUrl,
      'user_id': user.id,
      'status': 'published',
      'visibility': 'private',
    };
    
    try {
      final response = await _client.from('recipes').insert(recipeData).select().single();
      return _mapFromDatabase(Map<String, dynamic>.from(response));
    } catch (e) {
      // Log the full error for debugging
      print('Recipe save error: $e');
      print('Recipe data: $recipeData');
      
      // Try to extract more details from the error
      String errorMessage = 'Failed to save recipe';
      if (e.toString().contains('duplicate key')) {
        errorMessage = 'A recipe with this title already exists. Please try a different title.';
      } else if (e.toString().contains('null value')) {
        errorMessage = 'Missing required fields. Please check all recipe information.';
      } else if (e.toString().contains('check constraint')) {
        errorMessage = 'Invalid recipe data. Please check difficulty, servings, or time values.';
      } else {
        errorMessage = 'Failed to save recipe: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
    }
  }
  
  /// Map database response to Recipe model
  Recipe _mapFromDatabase(Map<String, dynamic> json) {
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
      prepTime: json['prep_time_minutes'] as int?,
      cookTime: json['cook_time_minutes'] as int?,
      servings: json['servings'] as int?,
      difficulty: json['difficulty'] as String?,
      cuisine: json['cuisine_type'] as String?,
      dietaryTags: (json['dietary_tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      imageUrl: json['primary_image_url'] as String?,
      isAiGenerated: true, // All saved recipes are AI generated
      isFavorite: false, // Will be set separately via recipe_favorites table
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Get all recipes for the current user
  Future<List<Recipe>> getRecipes() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('recipes')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // Note: recipe_favorites table references recipe_generations, not recipes
    // So we can't use it for recipes saved in the recipes table
    // For now, all saved recipes are considered favorites by default
    return (response as List<dynamic>)
        .map((e) => _mapFromDatabase(Map<String, dynamic>.from(e)).copyWith(isFavorite: true))
        .toList();
  }

  /// Get favorite recipes
  Future<List<Recipe>> getFavorites() async {
    // For now, return all recipes as favorites since recipe_favorites references recipe_generations
    // In the future, we might need a separate favorites mechanism for recipes table
    final allRecipes = await getRecipes();
    return allRecipes.where((r) => r.isFavorite).toList();
  }

  /// Toggle favorite flag
  /// Note: recipe_favorites table references recipe_generations, not recipes
  /// For now, this is a no-op for recipes in the recipes table
  /// In the future, we might need a separate favorites mechanism
  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    // TODO: Implement proper favorites for recipes table
    // For now, favorites are handled in-memory via the Recipe model's isFavorite field
    // The saved provider will handle the state update
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String recipeId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('recipes').delete().eq('id', recipeId).eq('user_id', user.id);
  }
}
