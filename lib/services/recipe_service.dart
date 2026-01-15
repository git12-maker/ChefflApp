import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/models/recipe.dart';
import 'supabase_service.dart';
import 'image_storage_service.dart';

/// Recipe service for Supabase CRUD operations
/// Implements best practices: automatic saving, proper favorites, accurate stats
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
  /// Returns the saved recipe with database ID
  Future<Recipe> saveRecipe(Recipe recipe) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if recipe already exists (by title and user_id to prevent duplicates)
    if (recipe.id != null) {
      // Recipe already has ID, check if it exists
      try {
        final existing = await _client
            .from('recipes')
            .select()
            .eq('id', recipe.id!)
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (existing != null) {
          // Recipe exists, return it
          return _mapFromDatabase(Map<String, dynamic>.from(existing));
        }
      } catch (_) {
        // Continue with save if check fails
      }
    }

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
      final savedRecipe = _mapFromDatabase(Map<String, dynamic>.from(response));
      
      // Check if this recipe is marked as favorite and add to recipe_saves
      if (recipe.isFavorite) {
        await _addToFavorites(savedRecipe.id!);
      }
      
      return savedRecipe;
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
  /// Also checks recipe_saves table to determine if recipe is favorited
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
      isFavorite: false, // Will be set separately when loading with favorites
      deleted: json['deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Get all recipes for the current user
  /// Includes favorite status from recipe_saves table
  Future<List<Recipe>> getRecipes() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get all recipes (exclude deleted recipes)
    final recipesResponse = await _client
        .from('recipes')
        .select()
        .eq('user_id', user.id)
        .eq('deleted', false) // Filter out deleted recipes
        .order('created_at', ascending: false);

    // Get all favorite recipe IDs from recipe_saves
    final favoritesResponse = await _client
        .from('recipe_saves')
        .select('recipe_id')
        .eq('user_id', user.id);

    final favoriteIds = (favoritesResponse as List<dynamic>)
        .map((e) => e['recipe_id']?.toString())
        .whereType<String>()
        .toSet();

    // Map recipes and set favorite status
    return (recipesResponse as List<dynamic>)
        .map((e) {
          final recipe = _mapFromDatabase(Map<String, dynamic>.from(e));
          return recipe.copyWith(
            isFavorite: favoriteIds.contains(recipe.id),
          );
        })
        .toList();
  }

  /// Get favorite recipes only
  Future<List<Recipe>> getFavorites() async {
    final allRecipes = await getRecipes();
    return allRecipes.where((r) => r.isFavorite).toList();
  }

  /// Toggle favorite status for a recipe
  /// Uses recipe_saves table to track favorites
  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (isFavorite) {
      // Add to favorites (recipe_saves)
      try {
        await _client.from('recipe_saves').insert({
          'user_id': user.id,
          'recipe_id': recipeId,
        });
      } catch (e) {
        // Ignore duplicate key errors (already favorited)
        if (!e.toString().contains('duplicate key')) {
          rethrow;
        }
      }
    } else {
      // Remove from favorites
      await _client
          .from('recipe_saves')
          .delete()
          .eq('user_id', user.id)
          .eq('recipe_id', recipeId);
    }
  }

  /// Add recipe to favorites (internal helper)
  Future<void> _addToFavorites(String recipeId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('recipe_saves').insert({
        'user_id': user.id,
        'recipe_id': recipeId,
      });
    } catch (e) {
      // Ignore duplicate key errors
      if (!e.toString().contains('duplicate key')) {
        rethrow;
      }
    }
  }

  /// Soft delete a recipe (sets deleted flag to true)
  /// Recipe remains in database but is hidden from user views
  /// Also removes from favorites (recipe_saves) if it exists there
  /// Best practice: Soft delete preserves data for statistics and recovery
  Future<void> deleteRecipe(String recipeId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Remove from favorites first (user shouldn't see deleted recipes in favorites)
    await _client
        .from('recipe_saves')
        .delete()
        .eq('user_id', user.id)
        .eq('recipe_id', recipeId);

    // Soft delete: set deleted flag to true instead of actually deleting
    await _client
        .from('recipes')
        .update({
          'deleted': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recipeId)
        .eq('user_id', user.id);
  }

  /// Get recipe statistics for a user
  /// Returns: total recipes, favorites count, recipes this month
  Future<Map<String, int>> getStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return {'total': 0, 'favorites': 0, 'thisMonth': 0};

    try {
      // Get total recipes count (exclude deleted recipes)
      final totalResponse = await _client
          .from('recipes')
          .select('id')
          .eq('user_id', user.id)
          .eq('deleted', false); // Exclude deleted recipes
      
      final total = (totalResponse as List).length;

      // Get favorites count (only non-deleted recipes can be favorited)
      // Note: recipe_saves only contains non-deleted recipes since we remove them on delete
      final favoritesResponse = await _client
          .from('recipe_saves')
          .select('id')
          .eq('user_id', user.id);
      
      final favorites = (favoritesResponse as List).length;

      // Get recipes this month (INCLUDE deleted recipes for accurate generation count)
      // This shows how many recipes were generated this month, regardless of deletion status
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      
      final thisMonthResponse = await _client
          .from('recipes')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', thisMonth.toIso8601String());
      // Note: No deleted filter here - we want to count all generated recipes this month
      
      final thisMonthCount = (thisMonthResponse as List).length;

      return {
        'total': total,
        'favorites': favorites,
        'thisMonth': thisMonthCount,
      };
    } catch (e) {
      return {'total': 0, 'favorites': 0, 'thisMonth': 0};
    }
  }

  /// Update recipe image URL in database
  /// Called when image generation completes
  Future<void> updateRecipeImage(String recipeId, String imageUrl) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Ensure image is stored in Supabase Storage
      final imageStorage = ImageStorageService.instance;
      String? finalImageUrl = imageUrl;
      
      if (!imageStorage.isSupabaseStorageUrl(imageUrl)) {
        final storedUrl = await imageStorage.uploadImageFromUrl(
          imageUrl: imageUrl,
          recipeId: recipeId,
        );
        if (storedUrl != null) {
          finalImageUrl = storedUrl;
        }
      }

      // Update recipe in database
      await _client
          .from('recipes')
          .update({'primary_image_url': finalImageUrl})
          .eq('id', recipeId)
          .eq('user_id', user.id);
    } catch (e) {
      print('Error updating recipe image: $e');
      rethrow;
    }
  }
}
