import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/openai_service.dart';
import '../../../services/image_storage_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/recipe_service.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/models/recipe_preferences.dart';

class GenerateState {
  const GenerateState({
    this.ingredients = const [],
    this.cookingMethods = const {},
    this.preferences = const RecipePreferences(),
    this.isLoading = false,
    this.imageLoading = false,
    this.loadingMessage,
    this.imageError,
    this.error,
    this.generatedRecipe,
  });

  final List<String> ingredients;
  final Map<String, String> cookingMethods; // ingredient name -> method name
  final RecipePreferences preferences;
  final bool isLoading;
  final bool imageLoading;
  final String? loadingMessage;
  final String? imageError;
  final String? error;
  final Recipe? generatedRecipe;

  GenerateState copyWith({
    List<String>? ingredients,
    Map<String, String>? cookingMethods,
    RecipePreferences? preferences,
    bool? isLoading,
    bool? imageLoading,
    String? loadingMessage,
    String? imageError,
    String? error,
    Recipe? generatedRecipe,
  }) {
    return GenerateState(
      ingredients: ingredients ?? this.ingredients,
      cookingMethods: cookingMethods ?? this.cookingMethods,
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      imageLoading: imageLoading ?? this.imageLoading,
      loadingMessage: loadingMessage,
      imageError: imageError,
      error: error,
      generatedRecipe: generatedRecipe ?? this.generatedRecipe,
    );
  }
}

final generateProvider =
    StateNotifierProvider<GenerateNotifier, GenerateState>((ref) {
  return GenerateNotifier();
});

class GenerateNotifier extends StateNotifier<GenerateState> {
  GenerateNotifier() : super(const GenerateState()) {
    _loadUserPreferences();
  }

  final _openAI = OpenAIService.instance;
  final _preferencesService = PreferencesService.instance;
  final _recipeService = RecipeService.instance;
  final _loadingMessages = const [
    'Chopping ingredients...',
    'Simmering ideas...',
    'Plating your recipe...',
    'Mixing flavors...',
    'Preheating inspiration...',
  ];

  Future<void> _loadUserPreferences() async {
    try {
      final userPrefs = await _preferencesService.getPreferences();
      // Apply user preferences to recipe preferences
      // Use first cuisine as primary, rest as influences
      final primaryCuisine = userPrefs.preferredCuisines.isNotEmpty
          ? userPrefs.preferredCuisines.first
          : null;
      final influences = userPrefs.preferredCuisines.length > 1
          ? userPrefs.preferredCuisines.sublist(1)
          : <String>[];
      
      state = state.copyWith(
        preferences: RecipePreferences(
          servings: userPrefs.defaultServings,
          dietaryRestrictions: userPrefs.dietaryPreferences,
          cuisine: primaryCuisine,
          cuisineInfluences: influences,
        ),
      );
    } catch (e) {
      // Keep defaults on error
    }
  }

  /// Reload user preferences (public method for external calls)
  Future<void> reloadUserPreferences() async {
    await _loadUserPreferences();
  }

  void addIngredient(String ingredient) {
    final value = ingredient.trim();
    if (value.isEmpty) return;
    if (state.ingredients.contains(value)) return;
    state = state.copyWith(
      ingredients: [...state.ingredients, value],
      error: null,
    );
  }

  void removeIngredient(String ingredient) {
    final updatedCookingMethods = Map<String, String>.from(state.cookingMethods)
      ..remove(ingredient);
    state = state.copyWith(
      ingredients: state.ingredients.where((e) => e != ingredient).toList(),
      cookingMethods: updatedCookingMethods,
      error: null,
    );
  }

  void updatePreferences(RecipePreferences preferences) {
    state = state.copyWith(preferences: preferences, error: null);
  }

  void setCookingMethod(String ingredient, String method) {
    final updated = Map<String, String>.from(state.cookingMethods);
    updated[ingredient] = method;
    state = state.copyWith(cookingMethods: updated);
  }

  void clearCookingMethod(String ingredient) {
    final updated = Map<String, String>.from(state.cookingMethods);
    updated.remove(ingredient);
    state = state.copyWith(cookingMethods: updated);
  }

  void clearAllCookingMethods() {
    state = state.copyWith(cookingMethods: {});
  }

  /// Update the generated recipe in state (used by screens to avoid accessing `state` directly)
  void setGeneratedRecipe(Recipe recipe) {
    state = state.copyWith(generatedRecipe: recipe);
  }

  Future<void> generateRecipe() async {
    if (state.ingredients.isEmpty) {
      state = state.copyWith(error: 'Add at least one ingredient');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null, // Clear any previous errors
      loadingMessage: _loadingMessages[Random().nextInt(_loadingMessages.length)],
      imageLoading: false,
      imageError: null,
      generatedRecipe: null, // Clear previous recipe when starting new generation
    );

    try {
      if (kDebugMode) {
        debugPrint('🔄 [GenerateProvider] Starting recipe generation...');
      }
      
      // Wrap in additional try-catch to catch any unexpected errors
      Recipe recipe;
      try {
        recipe = await _openAI.generateRecipe(
          ingredients: state.ingredients,
          preferences: state.preferences,
          cookingMethods: state.cookingMethods.isNotEmpty ? state.cookingMethods : null,
        );
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ [GenerateProvider] OpenAI service error: $e');
          debugPrint('Stack trace: $stackTrace');
        }
        rethrow; // Re-throw to be handled by outer catch
      }
      
      // Ensure recipe is valid before updating state
      if (recipe.title.isEmpty) {
        throw Exception('Generated recipe is invalid: missing title');
      }
      
      state = state.copyWith(
        generatedRecipe: recipe,
        isLoading: false,
        loadingMessage: null,
        error: null, // Clear any errors on success
      );

      // Automatically save recipe to database (best practice: save all generated recipes)
      // This happens in background so user can see recipe immediately
      // Don't await - let it run in background
      _autoSaveRecipe(recipe).catchError((e) {
        if (kDebugMode) {
          debugPrint('⚠️ [GenerateProvider] Auto-save failed: $e');
        }
        // Don't update state - auto-save failure shouldn't affect UI
      });

      // Always start image generation in background (don't await)
      // User can see recipe immediately while image loads
      // Image generation will continue on the recipe page
      _generateImage(recipe).catchError((e) {
        if (kDebugMode) {
          debugPrint('⚠️ [GenerateProvider] Image generation failed: $e');
        }
        // Don't update state - image generation failure shouldn't affect recipe display
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [GenerateProvider] Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      // Provide user-friendly error messages
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Check for API key error and provide helpful message
      if (errorMessage.contains('API key is not set')) {
        errorMessage = 'OpenAI API key is not configured. Please update lib/core/constants/env.dart with your API key.';
      } else if (errorMessage.contains('API key')) {
        errorMessage = 'Invalid API key. Please check your OpenAI API key in lib/core/constants/env.dart';
      } else if (errorMessage.toLowerCase().contains('network') || 
                 errorMessage.toLowerCase().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorMessage.toLowerCase().contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (errorMessage.toLowerCase().contains('json') || 
                 errorMessage.toLowerCase().contains('parse')) {
        errorMessage = 'Failed to parse recipe response. Please try again.';
      } else {
        // Generic error message for unexpected errors
        errorMessage = 'Failed to generate recipe. Please try again.';
      }
      
      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        error: errorMessage,
        generatedRecipe: null, // Ensure no partial recipe is shown
      );
    }
  }

  void setInitialIngredients(List<String> ingredients) {
    state = state.copyWith(
      ingredients: ingredients,
      error: null,
    );
  }

  /// Add multiple ingredients to existing list (for scan screen)
  void addIngredients(List<String> ingredients) {
    final newIngredients = ingredients
        .map((i) => i.trim())
        .where((i) => i.isNotEmpty)
        .where((i) => !state.ingredients.contains(i))
        .toList();
    
    if (newIngredients.isEmpty) return;
    
    state = state.copyWith(
      ingredients: [...state.ingredients, ...newIngredients],
      error: null,
    );
  }

  void clearAll() {
    state = const GenerateState();
  }

  /// Clear only the generated recipe and error, keep ingredients and preferences
  void clearRecipe() {
    state = state.copyWith(
      generatedRecipe: null,
      error: null,
      isLoading: false,
      loadingMessage: null,
      imageLoading: false,
      imageError: null,
    );
  }

  /// Manually trigger image generation (opt-in for free tier)
  /// Can also be called to continue image generation if recipe exists
  Future<void> generateImage() async {
    final recipe = state.generatedRecipe;
    if (recipe == null) return;
    
    // Don't start if already loading
    if (state.imageLoading) return;
    
    // Don't start if image already exists
    if (recipe.imageUrl != null) return;
    
    await _generateImage(recipe);
  }

  Future<void> _generateImage(Recipe recipe) async {
    state = state.copyWith(imageLoading: true, imageError: null);
    try {
      // Generate image using Replicate
      final generatedImageUrl = await _openAI.generateRecipeImage(
        recipe: recipe,
        cookingMethods: state.cookingMethods.isNotEmpty ? state.cookingMethods : null,
      );
      
      if (generatedImageUrl == null) {
        state = state.copyWith(
          imageLoading: false,
          imageError: 'Could not generate image',
        );
        return;
      }

      // Check if image is already in Supabase Storage
      final imageStorage = ImageStorageService.instance;
      if (imageStorage.isSupabaseStorageUrl(generatedImageUrl)) {
        // Already stored in Supabase, use it directly
        final updatedRecipe = state.generatedRecipe?.copyWith(imageUrl: generatedImageUrl);
        state = state.copyWith(
          generatedRecipe: updatedRecipe,
          imageLoading: false,
        );
        
        // Update image URL in database if recipe is already saved
        if (updatedRecipe?.id != null) {
          try {
            await _recipeService.updateRecipeImage(updatedRecipe!.id!, generatedImageUrl);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ [GenerateProvider] Failed to update image in database: $e');
            }
          }
        }
        return;
      }

      // Upload image to Supabase Storage for permanent storage
      // Use recipe ID or generate a temporary ID for storage path
      final recipeId = recipe.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final storedImageUrl = await imageStorage.uploadImageFromUrl(
        imageUrl: generatedImageUrl,
        recipeId: recipeId,
      );

      // Use stored URL if upload succeeded, otherwise fall back to original URL
      final finalImageUrl = storedImageUrl ?? generatedImageUrl;
      
      // Update recipe in state
      final updatedRecipe = state.generatedRecipe?.copyWith(imageUrl: finalImageUrl);
      state = state.copyWith(
        generatedRecipe: updatedRecipe,
        imageLoading: false,
      );

      // Update image URL in database if recipe is already saved
      if (updatedRecipe?.id != null) {
        try {
          await _recipeService.updateRecipeImage(updatedRecipe!.id!, finalImageUrl);
          if (kDebugMode) {
            debugPrint('✅ [GenerateProvider] Recipe image updated in database');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [GenerateProvider] Failed to update image in database: $e');
          }
          // Don't throw - image is still in state, just not in DB yet
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Image generation/storage error: $e');
      }
      state = state.copyWith(
        imageLoading: false,
        imageError: 'Could not generate image',
      );
    }
  }

  /// Automatically save recipe to database after generation
  /// Best practice: all generated recipes are automatically saved
  /// This runs in background and doesn't block the UI
  Future<void> _autoSaveRecipe(Recipe recipe) async {
    try {
      // Check if recipe already has an ID (already saved)
      if (recipe.id != null) {
        // Try to find existing recipe
        try {
          final existing = await _recipeService.getRecipes();
          if (existing.any((r) => r.id == recipe.id)) {
            // Recipe already exists, skip save
            if (kDebugMode) {
              debugPrint('✅ [GenerateProvider] Recipe already saved, skipping auto-save');
            }
            return;
          }
        } catch (_) {
          // Continue with save if check fails
        }
      }

      // Save recipe (without favorite status - user can favorite later)
      final savedRecipe = await _recipeService.saveRecipe(
        recipe.copyWith(isFavorite: false), // Don't auto-favorite
      );

      // Update state with saved recipe (includes database ID)
      state = state.copyWith(
        generatedRecipe: savedRecipe,
      );

      if (kDebugMode) {
        debugPrint('✅ [GenerateProvider] Recipe auto-saved: ${savedRecipe.id}');
      }
      
      // Note: Provider refresh is handled in recipe_result_screen
      // when it detects recipe has an ID
      // Profile stats will be refreshed when profile screen becomes visible
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GenerateProvider] Auto-save error: $e');
      }
      // Don't throw - auto-save failures shouldn't break the flow
    }
  }
}
